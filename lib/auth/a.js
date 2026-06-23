// test_login.js

async function checkRenderLogin() {
  const url = 'https://ruba-gsh7.onrender.com/api/users/login/';
  const payload = {
    username: '123456',
    password: '12341234'
  };

  console.log(`⏳ [1] جاري الاتصال بالرابط: ${url}`);
  console.log(`📦 [2] البيانات المرسلة:`, payload);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    console.log(`\n📡 [3] حالة السيرفر (Status): ${response.status} ${response.statusText}`);

    const responseText = await response.text();

    try {
      const jsonResponse = JSON.parse(responseText);
      
      if (response.ok) {
        console.log(`✅ [4] نجاح! الرد من السيرفر:`);
        console.dir(jsonResponse, { depth: null, colors: true });
      } else {
        console.log(`⚠️ [4] السيرفر رفض الطلب (خطأ بالبيانات أو الصلاحيات):`);
        console.dir(jsonResponse, { depth: null, colors: true });
      }
    } catch (parseError) {
      // إذا فشل التحويل، فهذا يعني أن الجانغو انهار وأرجع صفحة HTML
      console.log(`❌ [4] السيرفر انهار (Crash) وأرجع نصاً/HTML بدلاً من JSON!`);
      console.log(`🔍 [جزء من الرد لمعرفة المشكلة]:`);
      // طباعة أول 800 حرف من صفحة الخطأ لتحديد سبب المشكلة بدقة
      console.log(responseText.substring(0, 800));
    }

  } catch (networkError) {
    console.error(`\n🚨 [!] خطأ قاتل في الشبكة (السيرفر نائم، الرابط خاطئ، أو مشكلة DNS):`);
    console.error(networkError.message);
  }
}

checkRenderLogin();