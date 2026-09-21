# One-Click Language — Stable Final Setup

هذه النسخة تتجنب خدمات الترجمة العامة غير الرسمية التي كانت تسبب أخطاء مثل 429.

## الوظائف

- **Caps Lock**: تبديل لغة لوحة المفاتيح AR ↔ EN.
- **F8**: إظهار/إخفاء الشريط.
- **Translate / F9**: يشغّل DeepL الرسمي داخل المتصفح على النص المحدد.
- **Check Writing / F10**: يشغّل LanguageTool على الحقل الحالي.
- **Typing Settings**: يفتح إعدادات الكتابة في Windows.

## لماذا هذا الحل أكثر استقراراً؟

السكربت نفسه لا يتصل بأي API ترجمة أو تصحيح غير رسمي.
الترجمة تتم عبر إضافة DeepL الرسمية.
التصحيح يتم عبر إضافة LanguageTool الرسمية.

## إعداد مرة واحدة

1. ثبّت AutoHotkey v2.
2. ثبّت إضافة DeepL في المتصفح.
3. ثبّت إضافة LanguageTool في المتصفح.
4. في إعدادات LanguageTool فعّل الاختصار واجعله:
   Ctrl + Shift + Space
5. شغّل:
   one-click-language.ahk

بعد ذلك:
- ظلّل نصاً واضغط Translate أو F9.
- أثناء الكتابة سيعرض LanguageTool أخطاء الإملاء والقواعد تلقائياً.
- اضغط Check Writing أو F10 لفتح فحص LanguageTool بسرعة.
