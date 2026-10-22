/// All interface text in English and Egyptian Arabic.
///
/// Keys are short and grouped by screen. Use [Strings.of] through
/// `context.tr('key')` (see app_scope.dart).
class Strings {
  Strings(this.arabic);

  final bool arabic;

  String t(String key) {
    final entry = _all[key];
    if (entry == null) return key;
    return arabic ? entry[1] : entry[0];
  }

  /// Replaces {name} placeholders.
  String f(String key, Map<String, String> values) {
    var s = t(key);
    values.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  static const Map<String, List<String>> _all = {
    // General
    'app_name': ['Ozouma', 'عزومة'],
    'cancel': ['Cancel', 'إلغاء'],
    'save': ['Save', 'حفظ'],
    'done': ['Done', 'تمام'],
    'continue': ['Continue', 'متابعة'],
    'skip': ['Skip', 'تخطي'],
    'delete': ['Delete', 'مسح'],
    'min': ['min', 'دقيقة'],
    'serves': ['Serves {n}', 'تكفي {n}'],
    'steps_count': ['{n} steps', '{n} خطوات'],
    'timers_count': ['{n} timers', '{n} تايمر'],
    'minutes_short': ['{n} min', '{n} د'],

    // Tabs
    'tab_home': ['Home', 'الرئيسية'],
    'tab_add': ['Add', 'إضافة'],
    'tab_kitchen': ['Kitchen', 'مطبخي'],
    'tab_saved': ['Saved', 'المحفوظ'],
    'tab_profile': ['Profile', 'حسابي'],

    // Language picker
    'choose_language': ['Choose your language', 'اختاري لغتك'],
    'lang_ar_title': ['العربية (مصر)', 'العربية (مصر)'],
    'lang_ar_sub': ['Arabic screens and Egyptian voice commands', 'واجهة عربية وأوامر صوت بالمصري'],
    'lang_en_title': ['English', 'English'],
    'lang_en_sub': ['English screens and voice commands', 'واجهة وأوامر صوت بالإنجليزي'],
    'lang_note': ['You can change this any time in Profile.', 'تقدري تغيريها في أي وقت من حسابي.'],

    // Home
    'greeting': ['What are we cooking today?', 'هنطبخ إيه النهارده؟'],
    'search_hint': ['Search recipes or ingredients', 'دوري على أكلة أو مكون'],
    'cat_all': ['All', 'الكل'],
    'cat_egyptian': ['Egyptian', 'مصري'],
    'cat_quick': ['Under 30 min', 'أقل من ٣٠ دقيقة'],
    'cat_vegetarian': ['Vegetarian', 'نباتي'],
    'cat_dessert': ['Desserts', 'حلويات'],
    'cat_ramadan': ['Ramadan', 'رمضان'],
    'cook_with_what_i_have': ['Cook with what I have', 'اطبخي باللي عندك'],
    'cook_with_sub': ['Pick what is in your kitchen and see what you can make.', 'اختاري اللي في مطبخك وشوفي تعملي إيه.'],
    'no_results': ['No recipes match that yet.', 'مفيش أكلات مطابقة لسه.'],

    // Recipe
    'ingredients': ['Ingredients', 'المكونات'],
    'steps': ['Steps', 'الخطوات'],
    'start_cooking': ['Start cooking', 'يلا نطبخ'],
    'get_ingredients': ['Get ingredients', 'هاتي المكونات'],
    'added_to_list': ['Added {n} items to your shopping list', 'اتضاف {n} حاجات لقايمة المشتريات'],
    'servings': ['Servings', 'عدد الأفراد'],
    'saved_recipe': ['Saved', 'اتحفظت'],
    'save_recipe': ['Save recipe', 'احفظي الأكلة'],
    'source': ['Source', 'المصدر'],
    'timer_in_step': ['Timer: {t}', 'تايمر: {t}'],

    // Cooking mode
    'step_of': ['Step {n} of {total}', 'الخطوة {n} من {total}'],
    'listening': ['Listening', 'سامعاكي'],
    'mic_off': ['Mic off', 'المايك مقفول'],
    'tap_mode': ['Tap mode', 'وضع اللمس'],
    'say_next': ['Say "next"', 'قولي "اللي بعده"'],
    'back': ['Back', 'رجوع'],
    'next': ['Next', 'اللي بعده'],
    'finish': ['Finish', 'خلصت'],
    'exit': ['Exit', 'خروج'],
    'time_left': ['{t} left', 'فاضل {t}'],
    'starting_in': ['Timer starts in {n}', 'التايمر هيبدأ بعد {n}'],
    'paused': ['Paused', 'متوقف'],
    'timer_done': ['{name} is ready', '{name} جاهز'],
    'say_stop': ['Say "stop" or tap', 'قولي "خلاص" أو اضغطي'],
    'commands_title': ['You can say', 'تقدري تقولي'],
    'cmd_next': ['Next', 'اللي بعده'],
    'cmd_back': ['Back', 'ارجع'],
    'cmd_repeat': ['Repeat', 'تاني'],
    'cmd_pause': ['Pause / Resume', 'استنى / كمّل'],
    'cmd_ingredients': ['Ingredients', 'المكونات'],
    'cmd_how_long': ['How long?', 'فاضل قد إيه؟'],
    'cmd_stop': ['Stop (alarm)', 'خلاص (المنبه)'],
    'all_done_title': ['Bon appétit!', 'بالهنا والشفا!'],
    'all_done_sub': ['How did it turn out?', 'طلعت إزاي؟'],
    'rate_saved': ['Thanks, saved to your cooked list.', 'شكرًا، اتحفظت في الأكلات اللي طبختيها.'],
    'mic_denied': ['Microphone is off. You can still tap to move between steps.', 'المايك مقفول. تقدري تضغطي عشان تنقلي بين الخطوات.'],
    'step_ingredients': ['For this recipe', 'للأكلة دي'],

    // Kitchen
    'kitchen_title': ['My kitchen', 'مطبخي'],
    'pantry': ['What I have', 'اللي عندي'],
    'pantry_hint': ['Tap what is in your kitchen', 'اضغطي على اللي في مطبخك'],
    'you_can_make': ['You can make', 'تقدري تعملي'],
    'missing_n': ['Missing {n}', 'ناقص {n}'],
    'have_all': ['You have everything', 'عندك كل حاجة'],
    'shopping_list': ['Shopping list', 'قايمة المشتريات'],
    'shopping_empty': ['Nothing yet. Tap "Get ingredients" on any recipe.', 'لسه فاضية. اضغطي "هاتي المكونات" في أي أكلة.'],
    'open_in': ['Open in {store}', 'افتحي في {store}'],
    'clear_checked': ['Clear checked', 'امسحي اللي اتعلم عليه'],
    'store_note': ['Your list is copied, then the store opens. You order and pay in the store app.', 'القايمة بتتنسخ وبعدين المحل بيفتح. الطلب والدفع بيكونوا في تطبيق المحل.'],

    // Add / import
    'add_title': ['Add a recipe', 'ضيفي أكلة'],
    'add_link': ['Paste a link', 'الصقي لينك'],
    'add_link_hint': ['TikTok, Instagram, YouTube or any recipe site', 'تيك توك أو إنستجرام أو يوتيوب أو أي موقع'],
    'add_text': ['Paste the recipe text', 'الصقي نص الوصفة'],
    'add_text_hint': ['Paste ingredients and steps from WhatsApp, Facebook or notes', 'الصقي المكونات والخطوات من واتساب أو فيسبوك أو النوتس'],
    'read_recipe': ['Read the recipe', 'اقري الوصفة'],
    'title_label': ['Title', 'اسم الأكلة'],
    'review_recipe': ['Review recipe', 'راجعي الوصفة'],
    'found_summary': ['{i} ingredients · {s} steps · {t} timers found', '{i} مكونات · {s} خطوات · {t} تايمر'],
    'timers_are_guesses': ['Timers are suggestions. Edit the step text to change them.', 'التايمرات اقتراحات. عدلي نص الخطوة لو عايزة تغيريها.'],
    'nothing_found': ['We could not find steps in that text. Put each step on its own line.', 'ملقيناش خطوات في النص ده. حطي كل خطوة في سطر لوحدها.'],
    'link_saved_note': ['Video import from links is coming next. For now, paste the caption or recipe text below and keep the link as the source.', 'استيراد الفيديو من اللينك جاي قريب. دلوقتي الصقي الكابشن أو نص الوصفة تحت واللينك هيتحفظ كمصدر.'],
    'recipe_saved': ['Recipe saved', 'الوصفة اتحفظت'],

    // Saved
    'saved_title': ['Saved', 'المحفوظ'],
    'saved_empty': ['Recipes you save or import appear here.', 'الأكلات اللي تحفظيها أو تضيفيها هتظهر هنا.'],
    'from_you': ['Added by you', 'إضافتك'],
    'cooked_times': ['Cooked {n} times', 'اتطبخت {n} مرات'],

    // Profile / settings
    'profile_title': ['Profile', 'حسابي'],
    'settings': ['Settings', 'الإعدادات'],
    'app_language': ['App language', 'لغة التطبيق'],
    'voice_language': ['Voice language', 'لغة الصوت'],
    'voice_control': ['Voice control', 'التحكم بالصوت'],
    'read_aloud': ['Read each step aloud', 'اقري كل خطوة بصوت عالي'],
    'eastern_numerals': ['Arabic numerals (١٢٣)', 'أرقام عربية (١٢٣)'],
    'store': ['My grocery app', 'تطبيق البقالة'],
    'egyptian_arabic': ['Egyptian Arabic', 'مصري'],
    'english': ['English', 'إنجليزي'],
    'about': ['About Ozouma', 'عن عزومة'],
    'about_body': ['Hands-free cooking for home cooks. Say "next" and the step changes, timers start on their own and the screen stays on.', 'طبخ من غير لمس. قولي "اللي بعده" والخطوة تتغير، والتايمر يشتغل لوحده، والشاشة متطفيش.'],
  };
}
