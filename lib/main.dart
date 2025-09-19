import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _NotificationService.instance.init();
  runApp(const MyApp());
}

/// --------------------- تنظیمات برند ---------------------
const String kCompanyName = "شرکت شما";
const String kCompanyPhone = "09120000000";
const String kWhatsAppPhone = "989120000000"; // بدون + و با کد کشور
const String kTelegramUsername = "your_telegram"; // بدون @
const String kWebsite = "https://example.com";
const String kShareText = "اپ محاسبه میلگرد و ارتباط سریع با ما: https://example.com/app";

const Color kBrandColor = Color(0xFF1565C0);
const double kWeightConst = 0.006162; // kg/m
const double kDefaultBarLength = 12.0; // m
const double kPi = 3.14;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rebar Calc Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandColor),
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Root(),
      ),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _index = 0;
  List<String> gallery = [];
  List<Map<String, dynamic>> inbox = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    // Load gallery: list all files in assets/images via pubspec (we cannot list, so use predefined names or try common ones)
    // Approach: Keep static list or rely on developer to set names. We'll attempt known placeholders.
    final candidates = [
      'assets/images/slide1.txt',
      'assets/images/slide2.txt',
      'assets/images/slide3.txt',
    ];
    gallery = candidates; // replace with actual image paths (png/jpg)

    // Load messages
    try {
      final txt = await rootBundle.loadString('assets/data/messages.json');
      final List arr = json.decode(txt);
      inbox = arr.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(gallery: gallery, inbox: inbox),
      const CalculatorsPage(),
      GalleryPage(gallery: gallery),
      InboxPage(inbox: inbox),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        title: const Text('محاسبه میلگرد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(kShareText),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'محاسبات'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'گالری'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'پیام‌ها'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'تنظیمات'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _callNow,
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.call),
        label: const Text('تماس فوری'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _callNow() async {
    final uri = Uri(scheme: 'tel', path: kCompanyPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// --------------------- صفحه خانه ---------------------
class HomePage extends StatelessWidget {
  final List<String> gallery;
  final List<Map<String, dynamic>> inbox;
  const HomePage({super.key, required this.gallery, required this.inbox});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandHeader(),
          const SizedBox(height: 12),
          if (gallery.isNotEmpty) _PromoCarousel(gallery: gallery),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 12),
          const _ValueProps(),
          const SizedBox(height: 12),
          if (inbox.isNotEmpty) _LatestMessages(inbox: inbox.take(3).toList()),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBrandColor.withOpacity(.06),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kBrandColor.withOpacity(.15),
              child: const Icon(Icons.factory, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(kCompanyName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('tel:$kCompanyPhone')),
                    child: Row(children: const [
                      Icon(Icons.phone, size: 16, color: kBrandColor),
                      SizedBox(width: 6),
                      Text(kCompanyPhone, style: TextStyle(color: kBrandColor, fontWeight: FontWeight.w700)),
                    ]),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  final List<String> gallery;
  const _PromoCarousel({required this.gallery});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(height: 160, autoPlay: true, enlargeCenterPage: true),
      items: gallery.map((p) {
        return Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('بنر/تصویر: ${p.split('/').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionCard(icon: Icons.whatsapp, label: 'واتساپ', onTap: () {
          final url = Uri.parse('https://wa.me/$kWhatsAppPhone?text=%D8%B3%D9%84%D8%A7%D9%85');
          launchUrl(url, mode: LaunchMode.externalApplication);
        })),
        const SizedBox(width: 8),
        Expanded(child: _ActionCard(icon: Icons.telegram, label: 'تلگرام', onTap: () {
          final url = Uri.parse('https://t.me/$kTelegramUsername');
          launchUrl(url, mode: LaunchMode.externalApplication);
        })),
        const SizedBox(width: 8),
        Expanded(child: _ActionCard(icon: Icons.public, label: 'وب‌سایت', onTap: () {
          final url = Uri.parse(kWebsite);
          launchUrl(url, mode: LaunchMode.externalApplication);
        })),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kBrandColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueProps extends StatelessWidget {
  const _ValueProps();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ValueTile(title: 'حضور میدانی سریع', body: 'اعزام تیم اجرایی با هماهنگی تلفنی و بازدید رایگان'),
        _ValueTile(title: 'محاسبات دقیق و شفاف', body: 'کاهش پرت میلگرد و زمان اجرا با ابزارهای همین اپ'),
        _ValueTile(title: 'پشتیبانی مستقیم', body: 'هر زمان نیاز داشتید از داخل اپ تماس/واتساپ بگیرید'),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String title; final String body;
  const _ValueTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: kBrandColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
      ),
    );
  }
}

class _LatestMessages extends StatelessWidget {
  final List<Map<String, dynamic>> inbox;
  const _LatestMessages({required this.inbox});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('آخرین پیام‌ها', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...inbox.map((m) => Card(
          elevation: 0,
          color: Colors.lightBlue.withOpacity(.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(m['title'] ?? ''),
            subtitle: Text(m['body'] ?? ''),
            trailing: Text(m['type'] ?? ''),
          ),
        ))
      ],
    );
  }
}

/// --------------------- محاسبات ---------------------
class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});
  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('ابزارهای محاسباتی', style: TextStyle(fontWeight: FontWeight.w900)),
        TabBar(
          controller: _tab,
          dividerColor: Colors.transparent,
          labelColor: kBrandColor,
          tabs: const [
            Tab(text: 'تعویض میلگرد'),
            Tab(text: 'تعداد موردنیاز'),
            Tab(text: 'وزن'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              SubstitutionCalc(),
              NeedCountCalc(),
              WeightCalc(),
            ],
          ),
        )
      ],
    );
  }
}

double areaCm2(double dMm) => (kPi * dMm * dMm / 4.0) / 100.0; // mm²→cm²
double weightPerMeter(double dMm) => kWeightConst * dMm * dMm; // kg/m

/// 1) تعویض میلگرد (اصلی + تقویتی) → تبدیل به نمره موجود
class SubstitutionCalc extends StatefulWidget {
  const SubstitutionCalc({super.key});
  @override
  State<SubstitutionCalc> createState() => _SubstitutionCalcState();
}

class _SubstitutionCalcState extends State<SubstitutionCalc> {
  final dMainCtrl = TextEditingController();
  final nMainCtrl = TextEditingController();
  final dReinfCtrl = TextEditingController();
  final nReinfCtrl = TextEditingController();
  final dAvailCtrl = TextEditingController();

  double? reqArea; double? perAvail; double? needRaw; int? needCeil;

  void _calc(){
    final dMain = double.tryParse(dMainCtrl.text.replaceAll(',', '.')) ?? 0;
    final nMain = double.tryParse(nMainCtrl.text.replaceAll(',', '.')) ?? 0;
    final dReinf = double.tryParse(dReinfCtrl.text.replaceAll(',', '.')) ?? 0;
    final nReinf = double.tryParse(nReinfCtrl.text.replaceAll(',', '.')) ?? 0;
    final dAvail = double.tryParse(dAvailCtrl.text.replaceAll(',', '.')) ?? 0;

    final req = areaCm2(dMain) * nMain + areaCm2(dReinf) * nReinf;
    final per = areaCm2(dAvail);
    double raw = 0; int ceil = 0;
    if (per > 0) { raw = req / per; ceil = raw.ceil(); }

    setState((){ reqArea=req; perAvail=per; needRaw=raw; needCeil=ceil; });
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16,12,16,96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TipCard(text: 'اعداد را به میلی‌متر و تعداد وارد کنید. خروجی بر حسب تعداد میلگرد نمره موجود است.'),
          _NumField(ctrl: dMainCtrl, label:'نمره میلگرد اصلی نقشه (mm)'),
          _NumField(ctrl: nMainCtrl, label:'تعداد میلگرد اصلی نقشه'),
          _NumField(ctrl: dReinfCtrl, label:'نمره میلگرد تقویتی نقشه (mm)'),
          _NumField(ctrl: nReinfCtrl, label:'تعداد میلگرد تقویتی نقشه'),
          _NumField(ctrl: dAvailCtrl, label:'نمره میلگرد موجود (mm)'),
          const SizedBox(height: 8),
          _PrimaryBtn(text:'محاسبه', onTap:_calc),
          const SizedBox(height: 12),
          if (reqArea!=null) _OutTile(title:'سطح مقطع لازم (cm²)', value: reqArea!, digits: 4),
          if (perAvail!=null) _OutTile(title:'سطح مقطع هر میلگرد موجود (cm²)', value: perAvail!, digits: 4),
          if (needRaw!=null) _OutTile(title:'تعداد موردنیاز (اعشاری)', value: needRaw!, digits: 6),
          if (needCeil!=null) _OutTileInt(title:'تعداد موردنیاز (گرد به بالا)', value: needCeil!),
        ],
      ),
    );
  }
}

/// 2) تعداد میلگرد موردنیاز
class NeedCountCalc extends StatefulWidget {
  const NeedCountCalc({super.key});
  @override
  State<NeedCountCalc> createState() => _NeedCountCalcState();
}

class _NeedCountCalcState extends State<NeedCountCalc> {
  final dMapCtrl = TextEditingController();
  final nMapCtrl = TextEditingController();
  final dAvailCtrl = TextEditingController();

  double? reqArea; double? perAvail; double? needRaw; int? needCeil;

  void _calc(){
    final dMap = double.tryParse(dMapCtrl.text.replaceAll(',', '.')) ?? 0;
    final nMap = double.tryParse(nMapCtrl.text.replaceAll(',', '.')) ?? 0;
    final dAvail = double.tryParse(dAvailCtrl.text.replaceAll(',', '.')) ?? 0;

    final req = areaCm2(dMap) * nMap;
    final per = areaCm2(dAvail);
    double raw = 0; int ceil = 0;
    if (per > 0) { raw = req / per; ceil = raw.ceil(); }

    setState((){ reqArea=req; perAvail=per; needRaw=raw; needCeil=ceil; });
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16,12,16,96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumField(ctrl: dMapCtrl, label:'نمره میلگرد نقشه (mm)'),
          _NumField(ctrl: nMapCtrl, label:'تعداد میلگرد نقشه'),
          _NumField(ctrl: dAvailCtrl, label:'نمره میلگرد موجود (mm)'),
          const SizedBox(height: 8),
          _PrimaryBtn(text:'محاسبه', onTap:_calc),
          const SizedBox(height: 12),
          if (reqArea!=null) _OutTile(title:'سطح مقطع لازم (cm²)', value: reqArea!, digits: 4),
          if (perAvail!=null) _OutTile(title:'سطح مقطع هر میلگرد موجود (cm²)', value: perAvail!, digits: 4),
          if (needRaw!=null) _OutTile(title:'تعداد موردنیاز (اعشاری)', value: needRaw!, digits: 6),
          if (needCeil!=null) _OutTileInt(title:'تعداد موردنیاز (گرد به بالا)', value: needCeil!),
        ],
      ),
    );
  }
}

/// 3) وزن میلگرد
class WeightCalc extends StatefulWidget {
  const WeightCalc({super.key});
  @override
  State<WeightCalc> createState() => _WeightCalcState();
}

class _WeightCalcState extends State<WeightCalc> {
  final dCtrl = TextEditingController();
  final nCtrl = TextEditingController();
  final lenCtrl = TextEditingController(text: kDefaultBarLength.toString());

  double? total; int? totalRounded;

  void _calc(){
    final d = double.tryParse(dCtrl.text.replaceAll(',', '.')) ?? 0;
    final n = double.tryParse(nCtrl.text.replaceAll(',', '.')) ?? 0;
    final L = double.tryParse(lenCtrl.text.replaceAll(',', '.')) ?? kDefaultBarLength;
    final wpm = weightPerMeter(d);
    final t = n * L * wpm;
    setState((){ total=t; totalRounded=t.round(); });
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16,12,16,96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumField(ctrl: dCtrl, label:'نمره میلگرد (mm)'),
          _NumField(ctrl: nCtrl, label:'تعداد شاخه'),
          _NumField(ctrl: lenCtrl, label:'طول هر شاخه (m) - پیش‌فرض 12'),
          const SizedBox(height: 8),
          _PrimaryBtn(text:'محاسبه', onTap:_calc),
          const SizedBox(height: 12),
          if (total!=null) _OutTile(title:'وزن کل (کیلوگرم)', value: total!, digits: 6),
          if (totalRounded!=null) _OutTileInt(title:'وزن کل (گرد شده)', value: totalRounded!),
          const SizedBox(height: 8),
          const _TipCard(text:'فرمول: وزن بر متر = 0.006162 × d²  |  d بر حسب میلی‌متر'),
        ],
      ),
    );
  }
}

/// --------------------- گالری ---------------------
class GalleryPage extends StatelessWidget {
  final List<String> gallery;
  const GalleryPage({super.key, required this.gallery});

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) {
      return const Center(child: Text('تصویری بارگذاری نشده است. فایل‌های PNG/JPG را در مسیر assets/images قرار دهید.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: gallery.length,
      itemBuilder: (_, i) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text('بنر ${i+1}'),
          subtitle: Text(gallery[i].split('/').last),
          leading: const Icon(Icons.image, color: kBrandColor),
          trailing: IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(kShareText),
          ),
        ),
      ),
    );
  }
}

/// --------------------- پیام‌ها ---------------------
class InboxPage extends StatelessWidget {
  final List<Map<String, dynamic>> inbox;
  const InboxPage({super.key, required this.inbox});

  @override
  Widget build(BuildContext context) {
    if (inbox.isEmpty) return const Center(child: Text('پیامی موجود نیست.'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: inbox.length,
      itemBuilder: (_, i) {
        final m = inbox[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.campaign, color: kBrandColor),
            title: Text(m['title'] ?? ''),
            subtitle: Text(m['body'] ?? ''),
            trailing: Text(m['type'] ?? ''),
          ),
        );
      },
    );
  }
}

/// --------------------- تنظیمات ---------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifEnabled = false;
  TimeOfDay notifTime = const TimeOfDay(hour: 9, minute: 0);
  int everyNDays = 3;

  final wConstCtrl = TextEditingController(text: kWeightConst.toString());
  final barLenCtrl = TextEditingController(text: kDefaultBarLength.toString());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('یادآورهای تبلیغاتی', style: TextStyle(fontWeight: FontWeight.w900)),
          SwitchListTile(
            value: notifEnabled,
            title: const Text('ارسال اعلان‌های یادآور (آفلاین، بدون اینترنت)'),
            subtitle: Text('هر $everyNDays روز، ساعت ${notifTime.format(context)}'),
            onChanged: (v) async {
              setState(() => notifEnabled = v);
              if (v) {
                await _schedule();
              } else {
                await _NotificationService.instance.cancelAll();
              }
            },
          ),
          ListTile(
            title: const Text('زمان اعلان'),
            subtitle: Text(notifTime.format(context)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: notifTime);
              if (t != null) setState(() => notifTime = t);
              if (notifEnabled) await _schedule();
            },
          ),
          ListTile(
            title: const Text('هر چند روز یکبار؟'),
            subtitle: Text('$everyNDays روز'),
            trailing: const Icon(Icons.repeat),
            onTap: () async {
              final v = await showDialog<int>(context: context, builder: (_) => _NumberPickerDialog(init: everyNDays));
              if (v != null) setState(() => everyNDays = v);
              if (notifEnabled) await _schedule();
            },
          ),
          const SizedBox(height: 12),
          const Text('ضرایب و پیش‌فرض‌ها', style: TextStyle(fontWeight: FontWeight.w900)),
          _NumField(ctrl: wConstCtrl, label: 'ثابت وزن بر متر (kg/m)  | پیش‌فرض 0.006162'),
          _NumField(ctrl: barLenCtrl, label: 'طول شاخه (m)  | پیش‌فرض 12'),
          const SizedBox(height: 6),
          _PrimaryBtn(text: 'ذخیره و به‌روزرسانی', onTap: () {
            // توضیح: برای سادگی، این نمونه ثابت‌های بالای فایل را تغییر نمی‌دهد.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد (نمونهٔ نمایشی)')));
          }),
          const SizedBox(height: 16),
          const Text('پشتیبانی و ارتباط', style: TextStyle(fontWeight: FontWeight.w900)),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ElevatedButton.icon(onPressed: ()=> launchUrl(Uri.parse('tel:$kCompanyPhone')), icon: const Icon(Icons.call), label: const Text('تماس')),
              ElevatedButton.icon(onPressed: ()=> launchUrl(Uri.parse('https://wa.me/$kWhatsAppPhone')), icon: const Icon(Icons.whatsapp), label: const Text('واتساپ')),
              ElevatedButton.icon(onPressed: ()=> launchUrl(Uri.parse('https://t.me/$kTelegramUsername')), icon: const Icon(Icons.telegram), label: const Text('تلگرام')),
              ElevatedButton.icon(onPressed: ()=> Share.share(kShareText), icon: const Icon(Icons.share), label: const Text('اشتراک‌گذاری')),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _schedule() async {
    final now = TimeOfDay.now();
    final t = notifTime;
    await _NotificationService.instance.scheduleEveryNDays(
      hour: t.hour, minute: t.minute, everyNDays: everyNDays,
      title: 'یادآوری همکاری',
      body: 'برای پروژه بعدی روی ما حساب کنید — تماس: $kCompanyPhone',
    );
  }
}

class _NumberPickerDialog extends StatefulWidget {
  final int init;
  const _NumberPickerDialog({required this.init});
  @override
  State<_NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<_NumberPickerDialog> {
  late int val;
  @override
  void initState() { super.initState(); val = widget.init; }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('هر چند روز یکبار؟'),
      content: Row(children: [
        Expanded(child: Slider(min:1,max:14,divisions:13,value:val.toDouble(),onChanged:(v){setState(()=>val=v.toInt());})),
        SizedBox(width: 40, child: Text('$val')),
      ]),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('انصراف')),
        ElevatedButton(onPressed: ()=> Navigator.pop<int>(context, val), child: const Text('تایید')),
      ],
    );
  }
}

/// --------------------- اجزای UI مشترک ---------------------
class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _NumField({required this.ctrl, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.yellow.withOpacity(.12),
        ),
      ),
    );
  }
}

class _OutTile extends StatelessWidget {
  final String title; final double value; final int digits;
  const _OutTile({required this.title, required this.value, required this.digits});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.lightBlue.withOpacity(.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        trailing: Text(value.isFinite ? value.toStringAsFixed(digits) : '-', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _OutTileInt extends StatelessWidget {
  final String title; final int value;
  const _OutTileInt({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.lightBlue.withOpacity(.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        trailing: Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String text; final VoidCallback onTap;
  const _PrimaryBtn({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.calculate),
        label: Text(text),
        onPressed: onTap,
      ),
    );
  }
}

/// --------------------- اعلان‌ها ---------------------
class _NotificationService {
  _NotificationService._();
  static final instance = _NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit, iOS: null);
    await _plugin.initialize(init);
    try {
      tzdata.initializeTimeZones();
    } catch (_) {}
  }

  Future<void> scheduleEveryNDays({
    required int hour, required int minute, required int everyNDays,
    required String title, required String body,
  }) async {
    await cancelAll();
    final now = DateTime.now();
    DateTime first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) first = first.add(const Duration(days: 1));
    // schedule N notifications ahead
    for (int i=0; i<12; i++){ // ~ یک سال
      final when = first.add(Duration(days: i*everyNDays));
      await _plugin.zonedSchedule(
        1000+i,
        title, body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('promo_channel','یادآور تبلیغاتی',
              channelDescription: 'یادآورهای دوره‌ای برای یادآوری خدمات ما',
              importance: Importance.high, priority: Priority.high),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // fire at time; we control days manually
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

