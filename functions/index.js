const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

exports.abonelikBildirimGonder = functions.pubsub
    .schedule("every day 09:00")
    .timeZone("Europe/Istanbul")
    .onRun(async () => {
        try {
            const yarin = new Date();
            yarin.setDate(yarin.getDate() + 1);
            yarin.setHours(0, 0, 0, 0);

            const kullanicilar = await db.collection("kullanicilar").get();

            for (const doc of kullanicilar.docs) {
                const uid = doc.id;
                const token = doc.data().fcmToken;
                if (!token) continue;

                const abonelikler = await db
                    .collection("kullanicilar")
                    .doc(uid)
                    .collection("abonelik")
                    .get();

                for (const abone of abonelikler.docs) {
                    const veri = abone.data();
                    const tarih = veri.odemeTarihi?.toDate();
                    if (!tarih) continue;

                    tarih.setHours(0, 0, 0, 0);

                    if (tarih.getTime() === yarin.getTime()) {
                        console.log("Tarih eşleşti.");
                        const mesaj = {
                            notification: {
                                title: "Yarın ödeme günün var!",
                                body: `${veri.servisAdi} aboneliğin için ödeme tarihi yarın.`,
                            },
                            token: token,
                        };

                        try {
                            await admin.messaging().send(mesaj);
                            console.log(mesaj);
                            console.log(`Bildirim gönderildi: ${veri.servisAdi} → ${uid}`);
                        } catch (err) {
                            console.error(`Bildirim gönderilemedi: ${err.message}`);
                        }
                    }
                }
            }
            return null;
        } catch (err) {
            console.error("Fonksiyon hatası:", err.message);
        }
    });

//-------ABONELİK VE BİRİKİM TARİH GÜNCELLEMELERİ VE TAKİBİ---------

const addOneMonth = (date) => {
    const d = new Date(date);
    const g = d.getDate();
    d.setMonth(d.getMonth() + 1);
    if (d.getDate() < g) {
        d.setDate(0);
    }
    return d;
};

exports.abonelikOdemeTarihiGuncelle = functions.pubsub
    .schedule("every day 09:00")
    .timeZone("Europe/Istanbul")
    .onRun(async () => {
        const bugun = new Date();
        bugun.setHours(0, 0, 0, 0);

        const kullaniciSnapshot = await db.collection("kullanicilar").get();

        for (const doc of kullaniciSnapshot.docs) {
            const uid = doc.id;

            const abonelikler = await db
                .collection("kullanicilar")
                .doc(uid)
                .collection("abonelik")
                .get();

            for (const abonelik of abonelikler.docs) {
                const veri = abonelik.data();
                const odemeTarihi = veri.odemeTarihi?.toDate();

                if (!odemeTarihi) continue;

                const odemeGun = new Date(odemeTarihi);
                odemeGun.setHours(0, 0, 0, 0);

                if (odemeGun.getTime() !== bugun.getTime()) continue;

                const yeniTarih = addOneMonth(odemeTarihi);
                await db
                    .collection("kullanicilar")
                    .doc(uid)
                    .collection("abonelik")
                    .doc(abonelik.id)
                    .update({
                        odemeTarihi: Timestamp.fromDate(yeniTarih),
                    });

                console.log(`${uid} → ${veri.servisAdi} için tarih güncellendi: ${yeniTarih}`);
            }
        }

        return null;
    });

exports.birikimAylikArttir = functions.pubsub
    .schedule('every day 09:00')
    .timeZone('Europe/Istanbul')
    .onRun(async () => {
        const kullaniciSnapshot = await db.collection('kullanicilar').get();

        for (const doc of kullaniciSnapshot.docs) {
            const uid = doc.id;
            const hedefler = await db
                .collection('kullanicilar')
                .doc(uid)
                .collection('hedefbutce')
                .get();

            for (const hedef of hedefler.docs) {
                const data = hedef.data();

                const hedefTutar = parseFloat(data.hedefTutar) || 0;
                const mevcutDurum = parseFloat(data.mevcutDurum) || 0;
                const ek = parseFloat(data.aylikMiktar) || 0;

                const guncelDurum = mevcutDurum + ek;

                if (guncelDurum >= hedefTutar) {
                    console.log(`'${data.hedefAdi}' hedefe ulaştı ve silindi.`);
                    await hedef.ref.delete();
                    continue;
                }

                const tahminiBitis = data.tahminiBitis?.toDate();
                if (tahminiBitis) {
                    tahminiBitis.setHours(0, 0, 0, 0);
                    const bugun = new Date();
                    bugun.setHours(0, 0, 0, 0);
                    if (tahminiBitis <= bugun) {
                        console.log(`'${data.hedefAdi}' tahmini süresi doldu ve silindi.`);
                        await hedef.ref.delete();
                        continue;
                    }
                }

                await hedef.ref.update({
                    mevcutDurum: guncelDurum
                });

                console.log(`'${data.hedefAdi}' → ${ek} TL eklendi (toplam: ${guncelDurum})`);
            }
        }

        return null;
    });

//---------------ABONELİK KATEGORİLERİ---------------

async function abonelikKategoriAnaliz(uid, kategori) {
    const butceSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("butce")
        .orderBy("tarih", "desc")
        .limit(1)
        .get();

    const butce = butceSnapshot.empty
        ? 0
        : butceSnapshot.docs[0].data().tutar || 0;

    const kategoriSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("abonelik")
        .where("kategori", "==", kategori)
        .get();

    let toplamTutar = 0;
    kategoriSnapshot.forEach((doc) => {
        toplamTutar += doc.data().tutar || 0;
    });

    const butceYuzde = butce > 0 ? (toplamTutar / butce) * 100 : 0;

    await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("analiz")
        .doc("kategoriabonelik_" + kategori.toLowerCase())
        .set({
            kategori,
            tutar: toplamTutar,
            butceYuzde,
            guncelleme: admin.firestore.FieldValue.serverTimestamp(),
        });
}

//---------------HARCAMA KATEGORİLERİ---------------

async function harcamaKategoriAnaliz(uid, kategori) {
    const butceSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("butce")
        .orderBy("tarih", "desc")
        .limit(1)
        .get();

    const butce = butceSnapshot.empty
        ? 0
        : butceSnapshot.docs[0].data().tutar || 0;

    const kategoriSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("harcamalar")
        .where("kategori", "==", kategori)
        .get();

    let toplamTutar = 0;
    kategoriSnapshot.forEach((doc) => {
        toplamTutar += doc.data().tutar || 0;
    });

    const butceYuzde = butce > 0 ? (toplamTutar / butce) * 100 : 0;

    await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("analiz")
        .doc("kategoriharcamalar_" + kategori.toLowerCase())
        .set({
            kategori,
            tutar: toplamTutar,
            butceYuzde,
            guncelleme: admin.firestore.FieldValue.serverTimestamp(),
        });
}


//---------------GENEL ANALİZ---------------
async function analizGuncelle(uid) {
    const butceSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("butce")
        .orderBy("tarih", "desc")
        .limit(1)
        .get();

    const butce = butceSnapshot.empty
        ? 0
        : butceSnapshot.docs[0].data().tutar || 0;

    const harcamaSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("harcamalar")
        .get();

    let toplamHarcama = 0;
    harcamaSnapshot.forEach((doc) => {
        toplamHarcama += doc.data().tutar || 0;
    });

    const abonelikSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("abonelik")
        .get();

    let toplamAbonelik = 0;
    abonelikSnapshot.forEach((doc) => {
        toplamAbonelik += doc.data().tutar || 0;
    });

    const hedefSnapshot = await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("hedefbutce")
        .get();

    let aylikBirikimToplami = 0;
    hedefSnapshot.forEach((doc) => {
        aylikBirikimToplami += doc.data().aylikMiktar || 0;
    });


    const harcamaYuzde = butce > 0 ? (toplamHarcama / butce) * 100 : 0;
    const abonelikYuzde = butce > 0 ? (toplamAbonelik / butce) * 100 : 0;
    const toplamYuzdelik = harcamaYuzde + abonelikYuzde;

    await db
        .collection("kullanicilar")
        .doc(uid)
        .collection("analiz")
        .doc("ozet")
        .set({
            toplamHarcama,
            toplamAbonelik,
            aylikBirikimToplami,
            butce,
            kalan: butce - (toplamHarcama + toplamAbonelik + aylikBirikimToplami),
            harcamaYuzde,
            abonelikYuzde,
            toplamYuzdelik,
            guncellemeTarihi: admin.firestore.FieldValue.serverTimestamp(),
        });
    const harcamaKategorileri = [
        'Yiyecek',
        'Ulaşım',
        'Eğlence',
        'Zorunlu Giderler',
        'Diğer'
    ];

    for (const kategori of harcamaKategorileri) {
        await harcamaKategoriAnaliz(uid, kategori);
    }
    const abonelikKategorileri = [
        'Dijital Medya',
        'İnternet',
        'Üyelikler',
        'Diğer'
    ];

    for (const kategori of abonelikKategorileri) {
        await abonelikKategoriAnaliz(uid, kategori);
    }
}

exports.harcamaEkle = functions.firestore
    .document("kullanicilar/{uid}/harcamalar/{harcamaId}")
    .onCreate(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.harcamaGuncelle = functions.firestore
    .document("kullanicilar/{uid}/harcamalar/{harcamaId}")
    .onUpdate(async (change, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.harcamaSil = functions.firestore
    .document("kullanicilar/{uid}/harcamalar/{harcamaId}")
    .onDelete(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });


exports.abonelikEkle = functions.firestore
    .document("kullanicilar/{uid}/abonelik/{abonelikId}")
    .onCreate(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.abonelikGuncelle = functions.firestore
    .document("kullanicilar/{uid}/abonelik/{abonelikId}")
    .onUpdate(async (change, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.abonelikSil = functions.firestore
    .document("kullanicilar/{uid}/abonelik/{abonelikId}")
    .onDelete(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });
exports.birikimHedefEkle = functions.firestore
    .document('kullanicilar/{uid}/hedefbutce/{hedefId}')
    .onCreate(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.birikimHedefGuncelle = functions.firestore
    .document('kullanicilar/{uid}/hedefbutce/{hedefId}')
    .onUpdate(async (change, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

exports.birikimHedefSil = functions.firestore
    .document('kullanicilar/{uid}/hedefbutce/{hedefId}')
    .onDelete(async (snap, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });
exports.butceEkleVeyaGuncelle = functions.firestore
    .document("kullanicilar/{uid}/butce/{butceId}")
    .onWrite(async (change, context) => {
        const uid = context.params.uid;
        await analizGuncelle(uid);
    });

