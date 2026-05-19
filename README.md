Veritabanı Şeması (Supabase)
Projenin temelini oluşturan transactions tablosunun yapısı ve SQL tanımı aşağıdadır:

SQL

    CREATE TABLE public.transactions (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    description TEXT NOT NULL,
    is_debt BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT transactions_pkey PRIMARY KEY (id),
    CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE 
    );

    
Kurulum ve Çalıştırma Talimatları
1. Önkoşullar
Bilgisayarınızda Flutter SDK ($ \ge 3.0.0$) kurulu olmalıdır.

Android Studio veya VS Code üzerinde Flutter eklentileri aktif olmalıdır.

2. Supabase Projesinin Hazırlanması
Supabase adresine gidin ve yeni bir proje oluşturun.

SQL Editor sekmesine geçerek yukarıda verilen transactions tablosu SQL kodunu çalıştırın.

Project Settings -> API sekmesinden Project URL ve Anon Key bilgilerinizi alın.

3. Projenin Yerelde Çalıştırılması
Projeyi klonlayın veya zip dosyasını bir klasöre çıkarın.

lib/main.dart dosyasını açarak Supabase başlatma kodundaki yer tutucuları kendi API bilgilerinizle güncelleyin:

Dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
Terminali açıp proje dizinine gelin ve bağımlılıkları yükleyin:
flutter pub get

Bağlı bir emülatör veya gerçek cihaz üzerinde uygulamayı başlatın:
flutter run

Uygulama Giriş İçin Kullanıcı Bilgileri
1) test@meric.com - 123456789
2) ahmetsavas@gmail.com - 123456
   
Akademik Bilgiler
Üniversite: Selçuk Üniversitesi

Fakülte: Teknoloji Fakültesi

Bölüm: Bilgisayar Mühendisliği Bölümü

Ders: Mobil Programlama

Ödev: Final Projesi Teslimi

Ders Sorumlusu: Arş. Gör. Musa DOĞAN
"""

Save to a file
output_path = "README.md"
with open(output_path, "w", encoding="utf-8") as f:
f.write(readme_content)

print("README.md generated successfully.")
