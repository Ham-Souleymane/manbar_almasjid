import 'app_localizations.dart';

class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr(super.locale);

  // ── General ──────────────────────────────────────────────────
  @override String get appName => 'منبر المسجد';
  @override String get appTagline => 'تطبيق الإمام والمؤذن للمسجد';
  @override String get ok => 'حسنًا';
  @override String get cancel => 'إلغاء';
  @override String get save => 'حفظ';
  @override String get delete => 'حذف';
  @override String get edit => 'تعديل';
  @override String get next => 'التالي';
  @override String get back => 'رجوع';
  @override String get send => 'إرسال';
  @override String get logout => 'تسجيل الخروج';
  @override String get loading => 'جارٍ التحميل...';
  @override String get error => 'خطأ';
  @override String get orDivider => 'أو';
  @override String get copyright => '© 2025 منبر المسجد – جميع الحقوق محفوظة';
  @override String get noResults => 'لا توجد نتائج';

  // ── Auth ─────────────────────────────────────────────────────
  @override String get welcomeBack => 'أهلاً بعودتك — سجّل دخولك للمتابعة';
  @override String get createAccount => 'أنشئ حسابك الجديد';
  @override String get loginSubtitle => 'أهلاً بعودتك — سجّل دخولك للمتابعة';
  @override String get registerSubtitle => 'أنشئ حسابك الجديد';
  @override String get email => 'البريد الإلكتروني';
  @override String get emailHint => 'imam@masjid.com';
  @override String get password => 'كلمة المرور';
  @override String get confirmPassword => 'تأكيد كلمة المرور';
  @override String get forgotPassword => 'نسيت كلمة المرور؟';
  @override String get login => 'تسجيل الدخول';
  @override String get noAccount => 'ليس لديك حساب؟';
  @override String get hasAccount => 'لديك حساب بالفعل؟';
  @override String get registerCta => 'أنشئ حساباً';
  @override String get loginCta => 'تسجيل الدخول';
  @override String get registrationContinueNote => 'سيتم إكمال التسجيل في الخطوة التالية';
  @override String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';
  @override String get forgotPasswordSubtitle => 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.';
  @override String get resetLinkSent => 'تم إرسال رابط إعادة تعيين كلمة المرور إلى';
  @override String get continueWithGoogle => 'المتابعة عبر Google';
  @override String get continueWithApple => 'المتابعة عبر Apple';
  @override String get signInWithGoogle => 'تسجيل الدخول عبر Google';
  @override String get signInWithApple => 'تسجيل الدخول عبر Apple';

  // ── Validation ───────────────────────────────────────────────
  @override String get enterEmail => 'أدخل البريد الإلكتروني';
  @override String get invalidEmail => 'البريد الإلكتروني غير صالح';
  @override String get enterPassword => 'أدخل كلمة المرور';
  @override String get passwordMinLength => 'يجب أن تكون 6 أحرف على الأقل';
  @override String get enterConfirmPassword => 'أكّد كلمة المرور';
  @override String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';
  @override String get enterFullName => 'أدخل الاسم الكامل';
  @override String get enterPhone => 'أدخل رقم الهاتف';
  @override String get enterMosqueName => 'أدخل اسم المسجد';
  @override String get enterCity => 'أدخل المدينة';
  @override String get enterAddress => 'أدخل العنوان';
  @override String get enterContactNumber => 'أدخل رقم التواصل';
  @override String get selectCountry => 'يرجى اختيار الدولة';
  @override String get nameRequired => 'الاسم مطلوب';
  @override String get phoneRequired => 'رقم الهاتف مطلوب';
  @override String get selectCountryFirst => 'يرجى اختيار الدولة';
  @override String get selectMosqueLocation => 'يرجى تحديد موقع المسجد على الخريطة';
  @override String get anErrorOccurred => 'حدث خطأ';
  @override String get failedGoogleLogin => 'فشل تسجيل الدخول عبر Google';
  @override String get failedAppleLogin => 'فشل تسجيل الدخول عبر Apple';

  // ── Splash ───────────────────────────────────────────────────
  @override String get splashTagline => 'تطبيق الإمام والمؤذن للمسجد';

  // ── Home Dashboard ───────────────────────────────────────────
  @override String get greeting => 'السلام عليكم';
  @override String imamName(String name) => 'الإمام $name';
  @override String get pendingBanner => 'حسابك قيد المراجعة من الإدارة. لن تتمكن من النشر أو استخدام بعض الميزات حتى تتم الموافقة على حسابك.';
  @override String get locationUnset => 'الموقع غير محدد';
  @override String get publishAnnouncement => 'نشر إعلان';
  @override String get managePrayerTimes => 'إدارة أوقات الصلاة';
  @override String get viewPosts => 'عرض المنشورات';
  @override String get notificationsAlerts => 'رسائل وتنبيهات';
  @override String get todayStats => 'إحصائيات اليوم';
  @override String get views => 'مشاهدات';
  @override String get followers => 'متابعون';
  @override String get alerts => 'تنبيهات';
  @override String get errorLoadingProfile => 'خطأ في تحميل الملف الشخصي';
  @override String get errorLoadingMosque => 'خطأ في تحميل بيانات المسجد';
  @override String get mosqueDataNotFound => 'لم يتم العثور على بيانات المسجد';

  // ── Bottom Nav ───────────────────────────────────────────────
  @override String get navHome => 'الرئيسية';
  @override String get navQuestions => 'الأسئلة';
  @override String get navForum => 'الملتقى';
  @override String get navPosts => 'منشوراتي';
  @override String get navPrayer => 'الصلوات';
  @override String get navProfile => 'الحساب';
  @override String get navAdmin => 'إدارة';

  // ── Mosque Profile ───────────────────────────────────────────
  @override String get mosqueProfile => 'ملف المسجد';
  @override String get mosqueDetails => 'تفاصيل المسجد';
  @override String get country => 'الدولة';
  @override String get city => 'المدينة';
  @override String get address => 'العنوان';
  @override String get contactPhone => 'رقم التواصل';
  @override String get mosquePhoto => 'صورة المسجد';
  @override String get verified => 'موثّق';
  @override String get pending => 'قيد المراجعة';
  @override String get blocked => 'محظور';
  @override String get followersCount => 'متابع';
  @override String get postsCount => 'منشور';
  @override String get location => 'الموقع';
  @override String get editProfile => 'تعديل الملف';
  @override String get about => 'عن المسجد';
  @override String get detailedAddress => 'العنوان التفصيلي';
  @override String get imamPhone => 'رقم هاتف الإمام';
  @override String get description => 'الوصف';
  @override String get noDescriptionYet => 'لا يوجد وصف بعد.';
  @override String get noPostsYetMosque => 'لا توجد منشورات بعد';

  // ── Prayer Times ─────────────────────────────────────────────
  @override String get prayerTimes => 'أوقات الصلاة';
  @override String get fajr => 'الفجر';
  @override String get sunrise => 'الشروق';
  @override String get dhuhr => 'الظهر';
  @override String get asr => 'العصر';
  @override String get maghrib => 'المغرب';
  @override String get isha => 'العشاء';
  @override String get jumuah => 'الجمعة';
  @override String get calculationMethod => 'طريقة الحساب';
  @override String get editPrayerTimes => 'تعديل أوقات الصلاة';
  @override String get savePrayerTimes => 'حفظ التعديلات';
  @override String get prayerTimesUpdated => 'تم تحديث أوقات الصلاة';
  @override String get jumuahTime => 'وقت صلاة الجمعة';
  @override String get secondJumuah => 'الجمعة الثانية';
  @override String get secondJumuahTime => 'وقت الجمعة الثانية';
  @override String get jumuahKhateeb => 'الخطيب';
  @override String get jumuahTopic => 'موضوع الخطبة';
  @override String get methodUnset => 'غير محدد';
  @override String get alwaysManual => 'يدوي دائماً';
  @override String get jumuahKhutbah => 'خطبة الجمعة';
  @override String get useAutoCalculation => 'استخدام الحساب التلقائي';
  @override String get autoCalculationSubtitle => 'جلب الأوقات من واجهة برمجية (Aladhan)';
  @override String get fetchFailedBanner => 'لم يتم التحديث — يتم عرض آخر أوقات مخزّنة.';
  @override String get saving => 'جارٍ الحفظ...';

  // ── Posts ────────────────────────────────────────────────────
  @override String get myPosts => 'منشوراتي الإعلانية';
  @override String get noPostsYet => 'لا يوجد أي منشورات حالياً';
  @override String get noPostsSubtitle => 'انقر على "نشر إعلان" من الشاشة الرئيسية لإضافة منشور.';
  @override String get createPost => 'إنشاء منشور';
  @override String get postTitle => 'عنوان المنشور';
  @override String get postContent => 'محتوى المنشور';
  @override String get postCategory => 'الفئة';
  @override String get categoryLesson => 'درس';
  @override String get categoryKhutbah => 'خطبة';
  @override String get categoryActivity => 'نشاط';
  @override String get categoryAlert => 'تنبيه';
  @override String get categoryAnnouncement => 'إعلان';
  @override String get publishPost => 'نشر';
  @override String get deletePost => 'حذف المنشور';
  @override String get accountNotVerified => 'حسابك ليس مصدقاً. لا يمكن نشر الإعلانات حتى تتم الموافقة عليه.';
  @override String get postPublished => 'تم نشر المنشور بنجاح';
  @override String get enterPostContent => 'يرجى كتابة محتوى المنشور';
  @override String get postContentHint => 'اكتب إعلانك أو رسالتك هنا...';
  @override String get attachMedia => 'إرفاق وسائط (اختياري)';
  @override String get additionalOptions => 'خيارات إضافية';
  @override String get eventDateLabel => 'تاريخ الحدث/النشاط';
  @override String get selectEventDateHint => 'حدد موعداً (إذا كان المنشور لحدث معين)';
  @override String get schedulePublish => 'جدولة النشر';
  @override String get schedulePublishHint => 'حدد موعداً لاحقاً لنشر الإعلان تلقائياً';
  @override String get publishNow => 'نشر الآن';
  @override String get publishingPostMessage => 'جاري رفع الملفات ونشر الإعلان...';
  @override String get loadMore => 'تحميل المزيد';
  @override String get noMatchingPosts => 'لا توجد منشورات مطابقة';
  @override String get searchPostsHint => 'ابحث باسم المسجد أو الإمام...';
  @override String get imageLabel => 'صورة';
  @override String get videoLabel => 'فيديو';
  @override String get fileLabel => 'ملف';
  @override String get likes => 'إعجاب';
  @override String get comments => 'تعليق';
  @override String get likesCount => 'إعجاب';
  @override String get commentsLabel => 'التعليقات';
  @override String get postDeletedSuccessfully => 'تم حذف المنشور بنجاح';
  @override String get postUpdatedSuccessfully => 'تم تحديث المنشور بنجاح';
  @override String get postDetails => 'تفاصيل المنشور';
  @override String get postNotFound => 'عذراً، لم يتم العثور على هذا المنشور.';
  @override String get creationDate => 'تاريخ الإنشاء';
  @override String get scheduledPublishDate => 'موعد النشر المجدول';
  @override String get attachedVideoFile => 'ملف فيديو مرفق';
  @override String get attachedDocumentFile => 'مستند/ملف مرفق';
  @override String get noCommentsYet => 'لا توجد تعليقات بعد على هذا المنشور.';
  @override String get deleteComment => 'حذف التعليق';
  @override String get deleteCommentConfirm => 'هل أنت متأكد من رغبتك في حذف هذا التعليق؟ لا يمكن التراجع عن هذا الإجراء.';
  @override String get commentDeleted => 'تم حذف التعليق بنجاح';
  @override String get likesLabel => 'الإعجابات';
  @override String get noLikesYet => 'لا توجد إعجابات بعد على هذا المنشور.';

  // ── Registration ─────────────────────────────────────────────
  @override String get registerImam => 'تسجيل الإمام';
  @override String get imamData => 'بيانات الإمام';
  @override String get imamDataSubtitle => 'أدخل معلوماتك الشخصية للمتابعة';
  @override String get fullName => 'الاسم الكامل';
  @override String get fullNameHint => 'محمد أحمد';
  @override String get phoneHint => '+966 5XX XXX XXXX';
  @override String get passwordHint => '••••••••';
  @override String get registerMosque => 'تسجيل المسجد';
  @override String get mosqueData => 'بيانات المسجد';
  @override String get mosqueName => 'اسم المسجد';
  @override String get mosqueNameHint => 'مسجد النور';
  @override String get cityHint => 'تُملأ تلقائياً من الخريطة أو أدخلها يدوياً';
  @override String get addressHint => 'الشارع، الحي، الرمز البريدي...';
  @override String get contactHint => '+966 5XX XXX XXXX';
  @override String get countryLabel => 'الدولة';
  @override String get chooseCountry => 'اختر الدولة';
  @override String get uploadMosquePhoto => 'اضغط لرفع صورة للمسجد';
  @override String get saveAndSubmit => 'حفظ وإرسال للمراجعة';

  // ── Under Review ─────────────────────────────────────────────
  @override String get underReview => 'قيد المراجعة';
  @override String get underReviewMessage => 'تم استلام طلبك بنجاح. سيتم مراجعة بياناتك والموافقة عليها قريباً.';
  @override String get accountBlocked => 'الحساب محظور';
  @override String get accountBlockedMessage => 'لقد تم حظر حسابك من قبل الإدارة. يرجى التواصل مع الدعم الفني لمزيد من التفاصيل.';

  // ── Profile Settings ─────────────────────────────────────────
  @override String get profileSettings => 'حساب الإمام وإعداداته';
  @override String get editPersonalData => 'تعديل البيانات الشخصية';
  @override String get notificationSettings => 'إعدادات التنبيهات والرسائل';
  @override String get commentNotifications => 'تنبيهات التعليقات الجديدة';
  @override String get commentNotificationsSubtitle => 'استلام إشعار عند تعليق المصلين على منشوراتك';
  @override String get verificationNotifications => 'تنبيهات توثيق الحساب';
  @override String get verificationNotificationsSubtitle => 'تلقي إشعار عند قيام الإدارة بالموافقة على حسابك';
  @override String get accountManagement => 'إدارة الحساب';
  @override String get saveChanges => 'حفظ التعديلات';
  @override String get photoUpdated => 'تم تحديث الصورة الشخصية بنجاح';
  @override String get profileSaved => 'تم حفظ بيانات الحساب بنجاح';
  @override String get deleteAccount => 'حذف الحساب نهائيًا';
  @override String get deleteAccountTitle => 'حذف الحساب نهائياً';
  @override String get deleteAccountMessage => 'هل أنت متأكد تماماً من رغبتك في حذف حسابك؟ سيؤدي هذا إلى حذف ملفك الشخصي وبيانات مسجدك بالكامل من النظام ولا يمكن التراجع عن هذا الإجراء.';
  @override String get deleteAccountNow => 'حذف الحساب الآن';
  @override String get recentLoginRequired => 'مطلوب تسجيل الدخول مجدداً';
  @override String get recentLoginMessage => 'لحذف حسابك، يجب أن تكون قد سجلت الدخول حديثاً. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى وإجراء الحذف.';
  @override String get logoutNow => 'تسجيل الخروج الآن';
  @override String get preferencesUpdated => 'تم تحديث التفضيلات';
  @override String get language => 'اللغة';
  @override String get languageArabic => 'العربية';
  @override String get languageEnglish => 'English';
  @override String get imamLabel => 'الإمام';
  @override String get errorLoadingData => 'خطأ في تحميل البيانات';
  @override String get profileNotFound => 'لم يتم العثور على بيانات الملف الشخصي.';

  // ── Admin Panel ───────────────────────────────────────────────
  @override String get adminPanel => 'لوحة الإدارة';
  @override String get restrictedAccess => 'وصول مقيّد';
  @override String get restrictedMessage => 'هذه الصفحة متاحة للمسؤولين فقط.';
  @override String get pendingImams => 'الأئمة';
  @override String get reports => 'البلاغات';
  @override String get mosques => 'المساجد';
  @override String get posts => 'المنشورات';
  @override String get awaitingReview => 'بانتظار المراجعة';
  @override String get openReports => 'بلاغات مفتوحة';
  @override String get totalMosques => 'مسجد';
  @override String get totalPosts => 'منشور';
  @override String get deleteMosque => 'حذف المسجد';
  @override String get deleteMosqueConfirmTitle => 'حذف المسجد';
  @override String deleteMosqueConfirmBody(String name) => 'هل تريد حذف مسجد "$name" نهائياً من النظام؟ لا يمكن التراجع عن هذا الإجراء.';
  @override String get mosquePermanentlyDeleted => 'تم حذف المسجد بنجاح';
  @override String get searchMosqueHint => 'ابحث باسم المسجد أو المدينة...';
  @override String get noMatchingMosques => 'لا توجد نتائج مطابقة.';
  @override String get deletePostConfirmTitle => 'حذف المنشور';
  @override String get deletePostConfirmBody => 'هل تريد حذف هذا المنشور نهائياً؟ لا يمكن التراجع.';
  @override String get deleteFailed => 'فشل الحذف';
  @override String get allCategories => 'الكل';

  // ── Admin Imams Management ────────────────────────────────────
  @override String get searchImamHint => 'ابحث باسم الإمام، البريد أو الهاتف...';
  @override String get statusPending => 'قيد المراجعة';
  @override String get statusVerified => 'مقبول';
  @override String get statusBlocked => 'محظور';
  @override String get statusRejected => 'مرفوض';
  @override String get approve => 'قبول';
  @override String get reject => 'رفض';
  @override String get blockAccount => 'حظر الحساب';
  @override String get activateAccount => 'تفعيل الحساب';
  @override String get approveImam => 'قبول الإمام';
  @override String approveImamConfirm(String name) => 'هل تريد قبول $name وتفعيل حسابه ومسجده؟';
  @override String get imamApproved => 'تم قبول الإمام بنجاح';
  @override String get approveFailed => 'فشل القبول';
  @override String rejectImamTitle(String name) => 'رفض $name';
  @override String get rejectReasonOptional => 'يمكنك إضافة سبب الرفض (اختياري):';
  @override String get rejectReasonHint => 'سبب الرفض...';
  @override String get imamRejected => 'تم رفض الإمام';
  @override String get rejectFailed => 'فشل الرفض';
  @override String get blockImam => 'حظر الإمام';
  @override String blockImamConfirm(String name) => 'هل تريد حظر $name؟ لن يتمكن من استخدام التطبيق.';
  @override String get imamBlocked => 'تم حظر الإمام بنجاح';
  @override String get blockFailed => 'فشل الحظر';
  @override String get unblockImam => 'إلغاء حظر الإمام';
  @override String unblockImamConfirm(String name) => 'هل تريد إلغاء حظر $name؟';
  @override String get imamUnblocked => 'تم إلغاء حظر الإمام بنجاح';
  @override String get unblockFailed => 'فشل إلغاء الحظر';
  @override String get deleteImam => 'حذف الإمام';
  @override String deleteImamConfirm(String name) => 'هل أنت متأكد من رغبتك في حذف حساب $name نهائياً؟ لا يمكن التراجع عن هذا الإجراء.';
  @override String get imamDeleted => 'تم حذف الإمام بنجاح';
  @override String get registrationDate => 'تاريخ التسجيل';
  @override String get mosqueIdLabel => 'معرف المسجد';
  @override String get previouslyRejected => 'تم رفض هذا الحساب سابقاً';
  @override String get block => 'حظر';
  @override String get unblock => 'إلغاء الحظر';
  @override String get noMatchingImams => 'لا يوجد أئمة مطابقين للبحث';

  // ── Admin Posts ───────────────────────────────────────────────
  @override String get searchMosqueImamHint => 'ابحث باسم المسجد أو الإمام...';
  @override String get commentDeleteFailed => 'فشل حذف التعليق';

  // ── Notifications ─────────────────────────────────────────────
  @override String get notificationsTitle => 'التنبيهات والرسائل';
  @override String get noNotifications => 'لا توجد تنبيهات حالياً';
  @override String get markAllRead => 'قراءة الكل';
  @override String get notificationsSubtitle => 'ستظهر هنا الرسائل والتعليقات الجديدة فور حدوثها.';
  @override String get loginFirstForNotifications => 'يرجى تسجيل الدخول أولاً للوصول إلى التنبيهات.';
  // ── Unclaimed Mosques & Ask Sheikh Setup ─────────────────────
  @override String get selectExistingMosque => 'اختيار مسجد موجود';
  @override String get addNewMosque => 'تسجيل مسجد جديد';
  @override String get searchMosquePlaceholder => 'ابحث باسم المسجد، المدينة، أو الحي...';
  @override String get unclaimedMosquesTitle => 'المساجد غير المرتبطة بإمام';
  @override String get unclaimedMosquesSubtitle => 'اختر مسجدك إذا تمت إضافته مسبقاً من المصلين';
  @override String get noUnclaimedMosquesFound => 'لم يتم العثور على مساجد غير مرتبطة مطابقة لبحثك.';
  @override String get cantFindYourMosque => 'لم تجد مسجدك؟';
  @override String get clickToRegisterNewMosque => 'اضغط هنا لتسجيل مسجد جديد';
  @override String get claimMosque => 'اختيار المسجد';
  @override String get claimMosqueConfirmTitle => 'تأكيد اختيار المسجد';
  @override String claimMosqueConfirmMessage(String name, String city) => 'هل أنت متأكد من رغبتك في ربط نفسك كإمام لـ "$name" في $city؟';
  @override String get confirmClaim => 'تأكيد الاختيار';
  @override String get addedByWorshipper => 'أضيف بواسطة أحد المصلين';
  @override String distanceKm(String distance) => 'على بعد $distance كم';
  @override String distanceMeters(String distance) => 'على بعد $distance م';
  @override String get askFeatureSettings => 'إعدادات ميزة اسأل الشيخ';
  @override String get askFeatureSetupSubtitle => 'حدد تفضيلات استقبال الأسئلة واستشارات المصلين';
  @override String get acceptingQuestions => 'استقبال أسئلة واستشارات المصلين';
  @override String get acceptingQuestionsSubtitle => 'تفعيل أو إيقاف استقبال الأسئلة الجديدة مؤقتاً';
  @override String get imamSpecialties => 'المجالات والتخصصات الشرعية';
  @override String get imamSpecialtiesSubtitle => 'حدد المجالات التي ترغب في الإجابة عنها';
  @override String get imamBio => 'النبذة العلمية والمؤهلات';
  @override String get imamBioHint => 'مثال: خريج جامعة الأزهر، حافظ للقرآن الكريم ومجاز بالقراءات...';
  @override String get responseTime => 'المواعيد المتوقعة للرد وأوقات التواجد';
  @override String get responseTimeHint => 'مثال: الرد خلال 24-48 ساعة، أو بعد صلاة العصر';
  @override String get allowPrivateQuestions => 'السماح بالاستشارات والأسئلة الخاصة';
  @override String get allowPrivateQuestionsSubtitle => 'استقبال أسئلة خاصة 1-على-1 لا تظهر للعامة';
  @override String get completeRegistration => 'إتمام التسجيل';
  @override String get questionsPausedBanner => 'استقبال الأسئلة موقوف حالياً. انقر لإعادة التفعيل.';
  @override String get activateQuestions => 'تفعيل استقبال الأسئلة';
  @override String get pauseQuestions => 'إيقاف استقبال الأسئلة';
  @override String get selectAtLeastOneSpecialty => 'يرجى تحديد تخصص واحد على الأقل';
  @override String get mosqueSelected => 'تم اختيار المسجد بنجاح';
  @override String get loadingUnclaimedMosques => 'جارٍ البحث عن المساجد...';

  // ── Imam Forum & Specialized Group Chat ─────────────────────
  @override String get imamForum => 'ملتقى الأئمة';
  @override String get discoverGroups => 'استكشاف المجموعات (Discover Groups)';
  @override String get discoverGroupsSubtitle => 'تواصل مع الأئمة والعلماء في مجالات متخصصة. انضم للمناقشات وتبادل الخبرات في بيئة أكاديمية وروحانية.';
  @override String get searchGroups => 'البحث عن مجموعات...';
  @override String get joinGroup => 'انضم للمجموعة';
  @override String get joinedGroup => 'عضو';
  @override String get openChat => 'دخول المحادثة';
  @override String get requestToJoin => 'طلب انضمام';
  @override String get leaveGroup => 'مغادرة المجموعة';
  @override String get leaveGroupConfirm => 'هل أنت متأكد من رغبتك في مغادرة هذه المجموعة؟';
  @override String get groupMembers => 'الأعضاء';
  @override String get createGroup => 'إنشاء مجموعة جديدة';
  @override String get groupName => 'اسم المجموعة';
  @override String get groupDescription => 'وصف المجموعة';
  @override String get groupCategory => 'التخصص / الفئة';
  @override String get typeMessage => 'اكتب رسالتك هنا يا شيخ...';
  @override String get groupRules => 'آداب وضوابط الحوار العلمي';
  @override String get noGroupsFound => 'لم يتم العثور على مجموعات مطابقة';
  @override String membersCountLabel(int count) => '$count عضو';
  @override String get allSpecialties => 'الكل';
  @override String get manageGroups => 'إدارة المجموعات';
  @override String get groupCreatedSuccess => 'تم إنشاء المجموعة بنجاح';
}
