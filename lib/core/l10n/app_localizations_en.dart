import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn(super.locale);

  // ── General ──────────────────────────────────────────────────
  @override String get appName => 'Manbar AlMasjid';
  @override String get appTagline => 'The Imam & Muezzin App';
  @override String get ok => 'OK';
  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get delete => 'Delete';
  @override String get edit => 'Edit';
  @override String get next => 'Next';
  @override String get back => 'Back';
  @override String get send => 'Send';
  @override String get logout => 'Sign Out';
  @override String get loading => 'Loading...';
  @override String get error => 'Error';
  @override String get orDivider => 'or';
  @override String get copyright => '© 2025 Manbar AlMasjid – All rights reserved';
  @override String get noResults => 'No results found';

  // ── Auth ─────────────────────────────────────────────────────
  @override String get welcomeBack => 'Welcome back — sign in to continue';
  @override String get createAccount => 'Create your account';
  @override String get loginSubtitle => 'Welcome back — sign in to continue';
  @override String get registerSubtitle => 'Create your new account';
  @override String get email => 'Email Address';
  @override String get emailHint => 'imam@masjid.com';
  @override String get password => 'Password';
  @override String get confirmPassword => 'Confirm Password';
  @override String get forgotPassword => 'Forgot password?';
  @override String get login => 'Sign In';
  @override String get noAccount => 'Don\'t have an account?';
  @override String get hasAccount => 'Already have an account?';
  @override String get registerCta => 'Create an account';
  @override String get loginCta => 'Sign in';
  @override String get registrationContinueNote => 'Registration will continue in the next step';
  @override String get forgotPasswordTitle => 'Reset Password';
  @override String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you a reset link.';
  @override String get resetLinkSent => 'Password reset link sent to';
  @override String get continueWithGoogle => 'Continue with Google';
  @override String get continueWithApple => 'Continue with Apple';
  @override String get signInWithGoogle => 'Sign in with Google';
  @override String get signInWithApple => 'Sign in with Apple';

  // ── Validation ───────────────────────────────────────────────
  @override String get enterEmail => 'Enter your email address';
  @override String get invalidEmail => 'Invalid email address';
  @override String get enterPassword => 'Enter your password';
  @override String get passwordMinLength => 'Must be at least 6 characters';
  @override String get enterConfirmPassword => 'Confirm your password';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get enterFullName => 'Enter your full name';
  @override String get enterPhone => 'Enter your phone number';
  @override String get enterMosqueName => 'Enter mosque name';
  @override String get enterCity => 'Enter city';
  @override String get enterAddress => 'Enter address';
  @override String get enterContactNumber => 'Enter contact number';
  @override String get selectCountry => 'Please select a country';
  @override String get nameRequired => 'Name is required';
  @override String get phoneRequired => 'Phone number is required';
  @override String get selectCountryFirst => 'Please select a country first';
  @override String get selectMosqueLocation => 'Please select the mosque location on the map';
  @override String get anErrorOccurred => 'An error occurred';
  @override String get failedGoogleLogin => 'Google sign-in failed';
  @override String get failedAppleLogin => 'Apple sign-in failed';

  // ── Splash ───────────────────────────────────────────────────
  @override String get splashTagline => 'The Imam & Muezzin App for the Mosque';

  // ── Home Dashboard ───────────────────────────────────────────
  @override String get greeting => 'Peace be upon you';
  @override String imamName(String name) => 'Imam $name';
  @override String get pendingBanner => 'Your account is under review. You won\'t be able to post or use some features until your account is approved.';
  @override String get locationUnset => 'Location not set';
  @override String get publishAnnouncement => 'Post Announcement';
  @override String get managePrayerTimes => 'Manage Prayer Times';
  @override String get viewPosts => 'View Posts';
  @override String get notificationsAlerts => 'Messages & Alerts';
  @override String get todayStats => 'Today\'s Stats';
  @override String get views => 'Views';
  @override String get followers => 'Followers';
  @override String get alerts => 'Alerts';
  @override String get errorLoadingProfile => 'Error loading profile';
  @override String get errorLoadingMosque => 'Error loading mosque data';
  @override String get mosqueDataNotFound => 'Mosque data not found';

  // ── Bottom Nav ───────────────────────────────────────────────
  @override String get navHome => 'Home';
  @override String get navQuestions => 'Questions';
  @override String get navForum => 'Forum';
  @override String get navPosts => 'My Posts';
  @override String get navPrayer => 'Prayers';
  @override String get navProfile => 'Account';
  @override String get navAdmin => 'Admin';

  // ── Mosque Profile ───────────────────────────────────────────
  @override String get mosqueProfile => 'Mosque Profile';
  @override String get mosqueDetails => 'Mosque Details';
  @override String get country => 'Country';
  @override String get city => 'City';
  @override String get address => 'Address';
  @override String get contactPhone => 'Contact Phone';
  @override String get mosquePhoto => 'Mosque Photo';
  @override String get verified => 'Verified';
  @override String get pending => 'Pending Review';
  @override String get blocked => 'Blocked';
  @override String get followersCount => 'Followers';
  @override String get postsCount => 'Posts';
  @override String get location => 'Location';
  @override String get editProfile => 'Edit Profile';
  @override String get about => 'About Mosque';
  @override String get detailedAddress => 'Detailed Address';
  @override String get imamPhone => 'Imam\'s Phone';
  @override String get description => 'Description';
  @override String get noDescriptionYet => 'No description yet.';
  @override String get noPostsYetMosque => 'No posts yet';

  // ── Prayer Times ─────────────────────────────────────────────
  @override String get prayerTimes => 'Prayer Times';
  @override String get fajr => 'Fajr';
  @override String get sunrise => 'Sunrise';
  @override String get dhuhr => 'Dhuhr';
  @override String get asr => 'Asr';
  @override String get maghrib => 'Maghrib';
  @override String get isha => 'Isha';
  @override String get jumuah => 'Jumuah';
  @override String get calculationMethod => 'Calculation Method';
  @override String get editPrayerTimes => 'Edit Prayer Times';
  @override String get savePrayerTimes => 'Save Changes';
  @override String get prayerTimesUpdated => 'Prayer times updated';
  @override String get jumuahTime => 'Jumuah Prayer Time';
  @override String get secondJumuah => 'Second Jumuah';
  @override String get secondJumuahTime => 'Second Jumuah Time';
  @override String get jumuahKhateeb => 'Khateeb';
  @override String get jumuahTopic => 'Khutbah Topic';
  @override String get methodUnset => 'Not set';
  @override String get alwaysManual => 'Always Manual';
  @override String get jumuahKhutbah => 'Jumuah Khutbah';
  @override String get useAutoCalculation => 'Use Automatic Calculation';
  @override String get autoCalculationSubtitle => 'Fetch times from Aladhan API';
  @override String get fetchFailedBanner => 'Update failed — showing last cached times.';
  @override String get saving => 'Saving...';

  // ── Posts ────────────────────────────────────────────────────
  @override String get myPosts => 'My Posts';
  @override String get noPostsYet => 'No posts yet';
  @override String get noPostsSubtitle => 'Tap "Post Announcement" from the home screen to add a post.';
  @override String get createPost => 'Create Post';
  @override String get postTitle => 'Post Title';
  @override String get postContent => 'Post Content';
  @override String get postCategory => 'Category';
  @override String get categoryLesson => 'Lesson';
  @override String get categoryKhutbah => 'Khutbah';
  @override String get categoryActivity => 'Activity';
  @override String get categoryAlert => 'Alert';
  @override String get categoryAnnouncement => 'Announcement';
  @override String get publishPost => 'Publish';
  @override String get deletePost => 'Delete Post';
  @override String get accountNotVerified => 'Your account is not verified. You cannot publish announcements until it is approved.';
  @override String get postPublished => 'Post published successfully';
  @override String get enterPostContent => 'Please enter post content';
  @override String get postContentHint => 'Write your announcement or message here...';
  @override String get attachMedia => 'Attach media (optional)';
  @override String get additionalOptions => 'Additional options';
  @override String get eventDateLabel => 'Event Date/Activity';
  @override String get selectEventDateHint => 'Select date (if the post is for a specific event)';
  @override String get schedulePublish => 'Schedule Publish';
  @override String get schedulePublishHint => 'Select a future date to publish the post automatically';
  @override String get publishNow => 'Publish Now';
  @override String get publishingPostMessage => 'Uploading files and publishing post...';
  @override String get loadMore => 'Load More';
  @override String get noMatchingPosts => 'No matching posts';
  @override String get searchPostsHint => 'Search by mosque or imam name...';
  @override String get imageLabel => 'Image';
  @override String get videoLabel => 'Video';
  @override String get fileLabel => 'File';
  @override String get likes => 'likes';
  @override String get comments => 'comments';
  @override String get likesCount => 'likes';
  @override String get commentsLabel => 'Comments';
  @override String get postDeletedSuccessfully => 'Post deleted successfully';
  @override String get postUpdatedSuccessfully => 'Post updated successfully';
  @override String get postDetails => 'Post Details';
  @override String get postNotFound => 'Sorry, this post could not be found.';
  @override String get creationDate => 'Creation Date';
  @override String get scheduledPublishDate => 'Scheduled Publish Date';
  @override String get attachedVideoFile => 'Attached video file';
  @override String get attachedDocumentFile => 'Attached document/file';
  @override String get noCommentsYet => 'No comments yet on this post.';
  @override String get deleteComment => 'Delete Comment';
  @override String get deleteCommentConfirm => 'Are you sure you want to delete this comment? This action cannot be undone.';
  @override String get commentDeleted => 'Comment deleted successfully';
  @override String get likesLabel => 'Likes';
  @override String get noLikesYet => 'No likes yet on this post.';

  // ── Registration ─────────────────────────────────────────────
  @override String get registerImam => 'Imam Registration';
  @override String get imamData => 'Imam Details';
  @override String get imamDataSubtitle => 'Enter your personal information to continue';
  @override String get fullName => 'Full Name';
  @override String get fullNameHint => 'Mohammed Ahmed';
  @override String get phoneHint => '+966 5XX XXX XXXX';
  @override String get passwordHint => '••••••••';
  @override String get registerMosque => 'Mosque Registration';
  @override String get mosqueData => 'Mosque Details';
  @override String get mosqueName => 'Mosque Name';
  @override String get mosqueNameHint => 'Masjid Al-Noor';
  @override String get cityHint => 'Auto-filled from map or enter manually';
  @override String get addressHint => 'Street, district, postal code...';
  @override String get contactHint => '+966 5XX XXX XXXX';
  @override String get countryLabel => 'Country';
  @override String get chooseCountry => 'Choose country';
  @override String get uploadMosquePhoto => 'Tap to upload a mosque photo';
  @override String get saveAndSubmit => 'Save & Submit for Review';

  // ── Under Review ─────────────────────────────────────────────
  @override String get underReview => 'Under Review';
  @override String get underReviewMessage => 'Your request has been received. Your information will be reviewed and approved soon.';
  @override String get accountBlocked => 'Account Blocked';
  @override String get accountBlockedMessage => 'Your account has been blocked by the admin. Please contact support for more details.';

  // ── Profile Settings ─────────────────────────────────────────
  @override String get profileSettings => 'Account & Settings';
  @override String get editPersonalData => 'Edit Personal Information';
  @override String get notificationSettings => 'Notification Settings';
  @override String get commentNotifications => 'Comment Notifications';
  @override String get commentNotificationsSubtitle => 'Receive a notification when worshippers comment on your posts';
  @override String get verificationNotifications => 'Verification Notifications';
  @override String get verificationNotificationsSubtitle => 'Receive a notification when admin approves your account';
  @override String get accountManagement => 'Account Management';
  @override String get saveChanges => 'Save Changes';
  @override String get photoUpdated => 'Profile photo updated successfully';
  @override String get profileSaved => 'Account information saved successfully';
  @override String get deleteAccount => 'Delete Account Permanently';
  @override String get deleteAccountTitle => 'Delete Account Permanently';
  @override String get deleteAccountMessage => 'Are you sure you want to delete your account? This will permanently delete your profile and mosque data and cannot be undone.';
  @override String get deleteAccountNow => 'Delete Account Now';
  @override String get recentLoginRequired => 'Recent Login Required';
  @override String get recentLoginMessage => 'To delete your account, you must have logged in recently. Please sign out, sign back in, and try again.';
  @override String get logoutNow => 'Sign Out Now';
  @override String get preferencesUpdated => 'Preferences updated';
  @override String get language => 'Language';
  @override String get languageArabic => 'العربية';
  @override String get languageEnglish => 'English';
  @override String get imamLabel => 'Imam';
  @override String get errorLoadingData => 'Error loading data';
  @override String get profileNotFound => 'Profile data not found.';

  // ── Admin Panel ───────────────────────────────────────────────
  @override String get adminPanel => 'Admin Panel';
  @override String get restrictedAccess => 'Restricted Access';
  @override String get restrictedMessage => 'This page is only available to administrators.';
  @override String get pendingImams => 'Imams';
  @override String get reports => 'Reports';
  @override String get mosques => 'Mosques';
  @override String get posts => 'Posts';
  @override String get awaitingReview => 'Awaiting Review';
  @override String get openReports => 'Open Reports';
  @override String get totalMosques => 'Mosques';
  @override String get totalPosts => 'Posts';
  @override String get deleteMosque => 'Delete Mosque';
  @override String get deleteMosqueConfirmTitle => 'Delete Mosque';
  @override String deleteMosqueConfirmBody(String name) => 'Do you want to permanently delete "$name" from the system? This cannot be undone.';
  @override String get mosquePermanentlyDeleted => 'Mosque deleted successfully';
  @override String get searchMosqueHint => 'Search by mosque name or city...';
  @override String get noMatchingMosques => 'No matching results.';
  @override String get mapView => 'Map';
  @override String get listView => 'List';
  @override String get showOnMap => 'Show on map';
  @override String get fitAllMosques => 'Fit all mosques';
  @override String get noMosquesWithLocation => 'No mosques with recorded location';
  @override String get openInMaps => 'Directions';
  @override String mosquesOnMapCount(int count) => '$count mosques on map';
  @override String get deletePostConfirmTitle => 'Delete Post';
  @override String get deletePostConfirmBody => 'Do you want to permanently delete this post? This cannot be undone.';
  @override String get deleteFailed => 'Delete failed';
  @override String get allCategories => 'All';

  // ── Admin Imams Management ────────────────────────────────────
  @override String get searchImamHint => 'Search by imam name, email, or phone...';
  @override String get statusPending => 'Pending Review';
  @override String get statusVerified => 'Approved';
  @override String get statusBlocked => 'Blocked';
  @override String get statusRejected => 'Rejected';
  @override String get approve => 'Approve';
  @override String get reject => 'Reject';
  @override String get blockAccount => 'Block Account';
  @override String get activateAccount => 'Activate Account';
  @override String get approveImam => 'Approve Imam';
  @override String approveImamConfirm(String name) => 'Approve $name and activate their account and mosque?';
  @override String get imamApproved => 'Imam approved successfully';
  @override String get approveFailed => 'Approval failed';
  @override String rejectImamTitle(String name) => 'Reject $name';
  @override String get rejectReasonOptional => 'You may provide a reason for rejection (optional):';
  @override String get rejectReasonHint => 'Rejection reason...';
  @override String get imamRejected => 'Imam rejected';
  @override String get rejectFailed => 'Rejection failed';
  @override String get blockImam => 'Block Imam';
  @override String blockImamConfirm(String name) => 'Block $name? They will not be able to use the app.';
  @override String get imamBlocked => 'Imam blocked successfully';
  @override String get blockFailed => 'Block failed';
  @override String get unblockImam => 'Unblock Imam';
  @override String unblockImamConfirm(String name) => 'Unblock $name?';
  @override String get imamUnblocked => 'Imam unblocked successfully';
  @override String get unblockFailed => 'Unblock failed';
  @override String get deleteImam => 'Delete Imam';
  @override String deleteImamConfirm(String name) => 'Are you sure you want to permanently delete $name\'s account? This cannot be undone.';
  @override String get imamDeleted => 'Imam deleted successfully';
  @override String get registrationDate => 'Registration Date';
  @override String get mosqueIdLabel => 'Mosque ID';
  @override String get previouslyRejected => 'This account was previously rejected';
  @override String get block => 'Block';
  @override String get unblock => 'Unblock';
  @override String get noMatchingImams => 'No matching imams found';

  // ── Admin Posts ───────────────────────────────────────────────
  @override String get searchMosqueImamHint => 'Search by mosque or imam...';
  @override String get commentDeleteFailed => 'Failed to delete comment';

  // ── Notifications ─────────────────────────────────────────────
  @override String get notificationsTitle => 'Notifications';
  @override String get noNotifications => 'No notifications yet';
  @override String get markAllRead => 'Mark all as read';
  @override String get notificationsSubtitle => 'New messages and comments will appear here as they happen.';
  @override String get loginFirstForNotifications => 'Please log in first to access notifications.';
  // ── Unclaimed Mosques & Ask Sheikh Setup ─────────────────────
  @override String get selectExistingMosque => 'Select Existing Mosque';
  @override String get addNewMosque => 'Register New Mosque';
  @override String get searchMosquePlaceholder => 'Search by mosque name, city, or district...';
  @override String get unclaimedMosquesTitle => 'Unclaimed Mosques';
  @override String get unclaimedMosquesSubtitle => 'Select your mosque if worshippers already added it';
  @override String get noUnclaimedMosquesFound => 'No unclaimed mosques found matching your search.';
  @override String get cantFindYourMosque => 'Can\'t find your mosque?';
  @override String get clickToRegisterNewMosque => 'Click here to register a new mosque';
  @override String get claimMosque => 'Select Mosque';
  @override String get claimMosqueConfirmTitle => 'Confirm Mosque Selection';
  @override String claimMosqueConfirmMessage(String name, String city) => 'Are you sure you want to link yourself as Imam of "$name" in $city?';
  @override String get confirmClaim => 'Confirm Selection';
  @override String get addedByWorshipper => 'Added by a worshipper';
  @override String distanceKm(String distance) => '$distance km away';
  @override String distanceMeters(String distance) => '$distance m away';
  @override String get askFeatureSettings => 'Ask Sheikh Settings';
  @override String get askFeatureSetupSubtitle => 'Set your preferences for receiving worshipper questions';
  @override String get acceptingQuestions => 'Accept Questions & Consultations';
  @override String get acceptingQuestionsSubtitle => 'Enable or temporarily pause receiving new questions';
  @override String get imamSpecialties => 'Islamic Specialties & Topics';
  @override String get imamSpecialtiesSubtitle => 'Select the fields you would like to answer in';
  @override String get imamBio => 'Bio & Academic Credentials';
  @override String get imamBioHint => 'e.g. Al-Azhar graduate, Hafiz of the Quran...';
  @override String get responseTime => 'Expected Response Time & Availability';
  @override String get responseTimeHint => 'e.g. Answers within 24-48 hours, or after Asr';
  @override String get allowPrivateQuestions => 'Allow Private Consultations';
  @override String get allowPrivateQuestionsSubtitle => 'Receive 1-on-1 private questions hidden from public view';
  @override String get completeRegistration => 'Complete Registration';
  @override String get questionsPausedBanner => 'Questions are currently paused. Tap to re-enable.';
  @override String get activateQuestions => 'Enable Questions';
  @override String get pauseQuestions => 'Pause Questions';
  @override String get selectAtLeastOneSpecialty => 'Please select at least one specialty';
  @override String get mosqueSelected => 'Mosque selected successfully';
  @override String get loadingUnclaimedMosques => 'Searching for mosques...';

  // ── Imam Forum & Specialized Group Chat ─────────────────────
  @override String get imamForum => 'Imams Forum';
  @override String get discoverGroups => 'Discover Groups';
  @override String get discoverGroupsSubtitle => 'Connect with imams and scholars in specialized fields. Join discussions and share expertise in an academic and spiritual atmosphere.';
  @override String get searchGroups => 'Search groups...';
  @override String get joinGroup => 'Join Group';
  @override String get joinedGroup => 'Member';
  @override String get openChat => 'Open Chat';
  @override String get requestToJoin => 'Request to Join';
  @override String get leaveGroup => 'Leave Group';
  @override String get leaveGroupConfirm => 'Are you sure you want to leave this group?';
  @override String get groupMembers => 'Members';
  @override String get createGroup => 'Create New Group';
  @override String get groupName => 'Group Name';
  @override String get groupDescription => 'Group Description';
  @override String get groupCategory => 'Specialty / Category';
  @override String get typeMessage => 'Type your message...';
  @override String get groupRules => 'Discussion Guidelines';
  @override String get noGroupsFound => 'No matching groups found';
  @override String membersCountLabel(int count) => '$count members';
  @override String get allSpecialties => 'All';
  @override String get manageGroups => 'Manage Groups';
  @override String get groupCreatedSuccess => 'Group created successfully';

  // ── Mosque Registration Question ─────────────────────────────
  @override String get hasMosqueQuestion => 'Do you have a mosque?';
  @override String get hasMosqueSubtitle => 'You can link your mosque now or add it later from settings.';
  @override String get hasMosqueYes => 'Yes, I have a mosque';
  @override String get hasMosqueNo => 'No, I don\'t have a mosque yet';
  @override String get continueWithoutMosque => 'Continue without a mosque';
  @override String get continueBtn => 'Continue';
  @override String get postAsImam => 'Post as myself (not as Mosque)';
  @override String get postAsImamSubtitle => 'Your name will appear as the author instead of the Mosque\'s name';
  @override String get addMosqueLater => 'You can add your mosque later from settings';
  @override String get myMosque => 'My Mosque';
  @override String get myMosqueSubtitle => 'Add or link a mosque to your account';
  @override String get noMosqueLinked => 'No mosque linked';
  @override String get noMosqueLinkedSubtitle => 'You can pick an existing mosque or register a new one';
  @override String get linkMosque => 'Add / Link Mosque';
  @override String get linkMosqueSuccess => 'Mosque linked successfully';
  @override String get postingAsImam => 'Posting as yourself (Imam)';
  @override String get postingAsMosque => 'Posting as the Mosque';
}
