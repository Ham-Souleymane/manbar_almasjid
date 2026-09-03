import 'package:flutter/material.dart';

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

/// Abstract base class for all app localizations.
/// Add new strings here, then implement in _AppLocalizationsAr and _AppLocalizationsEn.
abstract class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // â”€â”€ General â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get appName;
  String get appTagline;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get next;
  String get back;
  String get send;
  String get logout;
  String get loading;
  String get error;
  String get orDivider;
  String get copyright;
  String get noResults;

  // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get welcomeBack;
  String get createAccount;
  String get loginSubtitle;
  String get registerSubtitle;
  String get email;
  String get emailHint;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get login;
  String get noAccount;
  String get hasAccount;
  String get registerCta;
  String get loginCta;
  String get registrationContinueNote;
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get resetLinkSent;
  String get continueWithGoogle;
  String get continueWithApple;
  String get signInWithGoogle;
  String get signInWithApple;

  // â”€â”€ Validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get enterEmail;
  String get invalidEmail;
  String get enterPassword;
  String get passwordMinLength;
  String get enterConfirmPassword;
  String get passwordsDoNotMatch;
  String get enterFullName;
  String get enterPhone;
  String get enterMosqueName;
  String get enterCity;
  String get enterAddress;
  String get enterContactNumber;
  String get selectCountry;
  String get nameRequired;
  String get phoneRequired;
  String get selectCountryFirst;
  String get selectMosqueLocation;
  String get anErrorOccurred;
  String get failedGoogleLogin;
  String get failedAppleLogin;

  // â”€â”€ Splash â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get splashTagline;

  // â”€â”€ Home Dashboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get greeting;
  String imamName(String name);
  String get pendingBanner;
  String get locationUnset;
  String get publishAnnouncement;
  String get managePrayerTimes;
  String get viewPosts;
  String get notificationsAlerts;
  String get todayStats;
  String get views;
  String get followers;
  String get alerts;
  String get errorLoadingProfile;
  String get errorLoadingMosque;
  String get mosqueDataNotFound;

  // ── Bottom Nav ──────────────────────────────────────────────────────────────
  String get navHome;
  String get navPosts;
  String get navQuestions;
  String get navForum;
  String get navPrayer;
  String get navProfile;
  String get navAdmin;

  // ── Mosque Profile ───────────────────────────────────────────────────────────
  String get mosqueProfile;
  String get mosqueDetails;
  String get country;
  String get city;
  String get address;
  String get contactPhone;
  String get mosquePhoto;
  String get verified;
  String get pending;
  String get blocked;
  String get followersCount;
  String get postsCount;
  String get location;
  String get editProfile;
  String get about;
  String get detailedAddress;
  String get imamPhone;
  String get description;
  String get noDescriptionYet;
  String get noPostsYetMosque;

  // â”€â”€ Prayer Times â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get prayerTimes;
  String get fajr;
  String get sunrise;
  String get dhuhr;
  String get asr;
  String get maghrib;
  String get isha;
  String get jumuah;
  String get calculationMethod;
  String get editPrayerTimes;
  String get savePrayerTimes;
  String get prayerTimesUpdated;
  String get jumuahTime;
  String get secondJumuah;
  String get secondJumuahTime;
  String get jumuahKhateeb;
  String get jumuahTopic;
  String get methodUnset;
  String get alwaysManual;
  String get jumuahKhutbah;
  String get useAutoCalculation;
  String get autoCalculationSubtitle;
  String get fetchFailedBanner;
  String get saving;

  // â”€â”€ Posts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get myPosts;
  String get noPostsYet;
  String get noPostsSubtitle;
  String get createPost;
  String get postTitle;
  String get postContent;
  String get postCategory;
  String get categoryLesson;
  String get categoryKhutbah;
  String get categoryActivity;
  String get categoryAlert;
  String get categoryAnnouncement;
  String get publishPost;
  String get deletePost;
  String get accountNotVerified;
  String get postPublished;
  String get enterPostContent;
  String get postContentHint;
  String get attachMedia;
  String get additionalOptions;
  String get eventDateLabel;
  String get selectEventDateHint;
  String get schedulePublish;
  String get schedulePublishHint;
  String get publishNow;
  String get publishingPostMessage;
  String get loadMore;
  String get noMatchingPosts;
  String get searchPostsHint;
  String get imageLabel;
  String get videoLabel;
  String get fileLabel;
  String get likes;
  String get comments;
  String get likesCount;
  String get commentsLabel;
  String get postDeletedSuccessfully;
  String get postUpdatedSuccessfully;
  String get postDetails;
  String get postNotFound;
  String get creationDate;
  String get scheduledPublishDate;
  String get attachedVideoFile;
  String get attachedDocumentFile;
  String get noCommentsYet;
  String get deleteComment;
  String get deleteCommentConfirm;
  String get commentDeleted;
  String get likesLabel;
  String get noLikesYet;

  // â”€â”€ Registration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get registerImam;
  String get imamData;
  String get imamDataSubtitle;
  String get fullName;
  String get fullNameHint;
  String get phoneHint;
  String get passwordHint;
  String get registerMosque;
  String get mosqueData;
  String get mosqueName;
  String get mosqueNameHint;
  String get cityHint;
  String get addressHint;
  String get contactHint;
  String get countryLabel;
  String get chooseCountry;
  String get uploadMosquePhoto;
  String get saveAndSubmit;

  // â”€â”€ Under Review â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get underReview;
  String get underReviewMessage;
  String get accountBlocked;
  String get accountBlockedMessage;

  // â”€â”€ Profile Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get profileSettings;
  String get editPersonalData;
  String get notificationSettings;
  String get commentNotifications;
  String get commentNotificationsSubtitle;
  String get verificationNotifications;
  String get verificationNotificationsSubtitle;
  String get accountManagement;
  String get saveChanges;
  String get photoUpdated;
  String get profileSaved;
  String get deleteAccount;
  String get deleteAccountTitle;
  String get deleteAccountMessage;
  String get deleteAccountNow;
  String get recentLoginRequired;
  String get recentLoginMessage;
  String get logoutNow;
  String get preferencesUpdated;
  String get language;
  String get languageArabic;
  String get languageEnglish;
  String get imamLabel;
  String get errorLoadingData;
  String get profileNotFound;

  // â”€â”€ Admin Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get adminPanel;
  String get restrictedAccess;
  String get restrictedMessage;
  String get pendingImams;
  String get reports;
  String get mosques;
  String get posts;
  String get awaitingReview;
  String get openReports;
  String get totalMosques;
  String get totalPosts;
  String get deleteMosque;
  String get deleteMosqueConfirmTitle;
  String deleteMosqueConfirmBody(String name);
  String get mosquePermanentlyDeleted;
  String get searchMosqueHint;
  String get noMatchingMosques;
  String get deletePostConfirmTitle;
  String get deletePostConfirmBody;
  String get deleteFailed;
  String get allCategories;

  // â”€â”€ Admin Imams Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get searchImamHint;
  String get statusPending;
  String get statusVerified;
  String get statusBlocked;
  String get statusRejected;
  String get approve;
  String get reject;
  String get blockAccount;
  String get activateAccount;
  String get approveImam;
  String approveImamConfirm(String name);
  String get imamApproved;
  String get approveFailed;
  String rejectImamTitle(String name);
  String get rejectReasonOptional;
  String get rejectReasonHint;
  String get imamRejected;
  String get rejectFailed;
  String get blockImam;
  String blockImamConfirm(String name);
  String get imamBlocked;
  String get blockFailed;
  String get unblockImam;
  String unblockImamConfirm(String name);
  String get imamUnblocked;
  String get unblockFailed;
  String get deleteImam;
  String deleteImamConfirm(String name);
  String get imamDeleted;
  String get registrationDate;
  String get mosqueIdLabel;
  String get previouslyRejected;
  String get block;
  String get unblock;
  String get noMatchingImams;

  // â”€â”€ Admin Posts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get searchMosqueImamHint;
  String get commentDeleteFailed;

  // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get notificationsTitle;
  String get noNotifications;
  String get markAllRead;
  String get notificationsSubtitle;
  String get loginFirstForNotifications;
  // ── Unclaimed Mosques & Ask Sheikh Setup ─────────────────────
  String get selectExistingMosque;
  String get addNewMosque;
  String get searchMosquePlaceholder;
  String get unclaimedMosquesTitle;
  String get unclaimedMosquesSubtitle;
  String get noUnclaimedMosquesFound;
  String get cantFindYourMosque;
  String get clickToRegisterNewMosque;
  String get claimMosque;
  String get claimMosqueConfirmTitle;
  String claimMosqueConfirmMessage(String name, String city);
  String get confirmClaim;
  String get addedByWorshipper;
  String distanceKm(String distance);
  String distanceMeters(String distance);
  String get askFeatureSettings;
  String get askFeatureSetupSubtitle;
  String get acceptingQuestions;
  String get acceptingQuestionsSubtitle;
  String get imamSpecialties;
  String get imamSpecialtiesSubtitle;
  String get imamBio;
  String get imamBioHint;
  String get responseTime;
  String get responseTimeHint;
  String get allowPrivateQuestions;
  String get allowPrivateQuestionsSubtitle;
  String get completeRegistration;
  String get questionsPausedBanner;
  String get activateQuestions;
  String get pauseQuestions;
  String get selectAtLeastOneSpecialty;
  String get mosqueSelected;
  String get loadingUnclaimedMosques;

  // ── Imam Forum & Specialized Group Chat ─────────────────────
  String get imamForum;
  String get discoverGroups;
  String get discoverGroupsSubtitle;
  String get searchGroups;
  String get joinGroup;
  String get joinedGroup;
  String get openChat;
  String get requestToJoin;
  String get leaveGroup;
  String get leaveGroupConfirm;
  String get groupMembers;
  String get createGroup;
  String get groupName;
  String get groupDescription;
  String get groupCategory;
  String get typeMessage;
  String get groupRules;
  String get noGroupsFound;
  String membersCountLabel(int count);
  String get allSpecialties;
  String get manageGroups;
  String get groupCreatedSuccess;
}

// ── Delegate ─────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'en') {
      return AppLocalizationsEn(locale);
    }
    return AppLocalizationsAr(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── BuildContext Extension ─────────────────────────────────────────
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
