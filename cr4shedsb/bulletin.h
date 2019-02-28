#include <dlfcn.h>

@interface BBAction : NSObject

+(id)actionWithLaunchURL:(id)arg1 callblock:(/*^block*/id)arg2 ;
+(id)actionWithLaunchBundleID:(id)arg1 callblock:(/*^block*/id)arg2 ;
+(id)actionWithCallblock:(/*^block*/id)arg1 ;
+(id)actionWithAppearance:(id)arg1 ;
+(id)actionWithLaunchURL:(id)arg1 ;
+(id)actionWithActivatePluginName:(id)arg1 activationContext:(id)arg2 ;
+(id)actionWithIdentifier:(id)arg1 ;
+(id)actionWithIdentifier:(id)arg1 title:(id)arg2 ;
+(id)actionWithLaunchBundleID:(id)arg1 ;
@end

@interface BBBulletin : NSObject
@property (nonatomic,readonly) NSString * sectionDisplayName;
@property (nonatomic,readonly) BOOL sectionDisplaysCriticalBulletins;
@property (nonatomic,readonly) BOOL showsSubtitle;
@property (nonatomic,readonly) unsigned long long messageNumberOfLines;
@property (nonatomic,readonly) BOOL usesVariableLayout;
@property (nonatomic,readonly) BOOL orderSectionUsingRecencyDate;
@property (nonatomic,readonly) BOOL showsDateInFloatingLockScreenAlert;
@property (nonatomic,readonly) NSString * subtypeSummaryFormat;
@property (nonatomic,readonly) NSString * hiddenPreviewsBodyPlaceholder;
@property (nonatomic,readonly) NSString * missedBannerDescriptionFormat;
@property (nonatomic,readonly) NSString * fullUnlockActionLabel;
@property (nonatomic,readonly) NSString * unlockActionLabel;
@property (nonatomic,readonly) NSSet * alertSuppressionAppIDs;
@property (nonatomic,readonly) BOOL suppressesAlertsWhenAppIsActive;
@property (nonatomic,readonly) BOOL coalescesWhenLocked;
@property (nonatomic,readonly) unsigned long long realertCount;
@property (nonatomic,readonly) BOOL inertWhenLocked;
@property (nonatomic,readonly) BOOL preservesUnlockActionCase;
@property (nonatomic,readonly) BOOL visuallyIndicatesWhenDateIsInFuture;
@property (nonatomic,readonly) NSString * fullAlternateActionLabel;
@property (nonatomic,readonly) NSString * alternateActionLabel;
@property (nonatomic,readonly) BOOL canBeSilencedByMenuButtonPress;
@property (nonatomic,readonly) BOOL preventLock;
@property (nonatomic,readonly) BOOL suppressesTitle;
@property (nonatomic,readonly) BOOL showsUnreadIndicatorForNoticesFeed;
@property (nonatomic,readonly) BOOL showsContactPhoto;
@property (nonatomic,readonly) BOOL playsSoundForModify;
@property (nonatomic,readonly) BOOL allowsAutomaticRemovalFromLockScreen;
@property (nonatomic,readonly) BOOL allowsAddingToLockScreenWhenUnlocked;
@property (nonatomic,readonly) BOOL prioritizeAtTopOfLockScreen;
@property (nonatomic,readonly) BOOL preemptsPresentedAlert;
@property (nonatomic,readonly) BOOL revealsAdditionalContentOnPresentation;
@property (nonatomic,readonly) BOOL shouldDismissBulletinWhenClosed;
@property (nonatomic,readonly) unsigned long long subtypePriority;
@property (nonatomic,readonly) long long iPodOutAlertType;
@property (nonatomic,readonly) NSString * bannerAccessoryRemoteViewControllerClassName;
@property (nonatomic,readonly) NSString * bannerAccessoryRemoteServiceBundleIdentifier;
@property (nonatomic,readonly) NSString * secondaryContentRemoteViewControllerClassName;
@property (nonatomic,readonly) NSString * secondaryContentRemoteServiceBundleIdentifier;
@property (nonatomic,readonly) unsigned long long privacySettings;
@property (nonatomic,readonly) BOOL suppressesMessageForPrivacy;
@property (nonatomic,readonly) NSString * topic;
@property (nonatomic,copy) NSString * section;
@property (nonatomic,copy) NSString * sectionID;                                                      //@synthesize sectionID=_sectionID - In the implementation block
@property (nonatomic,copy) NSSet * subsectionIDs;                                                     //@synthesize subsectionIDs=_subsectionIDs - In the implementation block
@property (nonatomic,copy) NSString * recordID;                                                       //@synthesize publisherRecordID=_publisherRecordID - In the implementation block
@property (nonatomic,copy) NSString * publisherBulletinID;                                            //@synthesize publisherBulletinID=_publisherBulletinID - In the implementation block
@property (nonatomic,copy) NSString * dismissalID;                                                    //@synthesize dismissalID=_dismissalID - In the implementation block
@property (nonatomic,copy) NSString * categoryID;                                                     //@synthesize categoryID=_categoryID - In the implementation block
@property (nonatomic,copy) NSString * threadID;                                                       //@synthesize threadID=_threadID - In the implementation block
@property (nonatomic,copy) NSArray * peopleIDs;                                                       //@synthesize peopleIDs=_peopleIDs - In the implementation block
@property (assign,nonatomic) long long addressBookRecordID;                                           //@synthesize addressBookRecordID=_addressBookRecordID - In the implementation block
@property (assign,nonatomic) long long sectionSubtype;                                                //@synthesize sectionSubtype=_sectionSubtype - In the implementation block
@property (nonatomic,copy) NSArray * intentIDs;                                                       //@synthesize intentIDs=_intentIDs - In the implementation block
@property (assign,nonatomic) unsigned long long counter;                                              //@synthesize counter=_counter - In the implementation block
@property (nonatomic,copy) NSString * header;                                                         //@synthesize header=_header - In the implementation block
@property (nonatomic,copy) NSString * title;
@property (nonatomic,copy) NSString * subtitle;
@property (nonatomic,copy) NSString * message;
@property (nonatomic,copy) NSString * summaryArgument;                                                //@synthesize summaryArgument=_summaryArgument - In the implementation block
@property (assign,nonatomic) unsigned long long summaryArgumentCount;                                 //@synthesize summaryArgumentCount=_summaryArgumentCount - In the implementation block
@property (assign,nonatomic) BOOL hasCriticalIcon;                                                    //@synthesize hasCriticalIcon=_hasCriticalIcon - In the implementation block
@property (assign,nonatomic) BOOL hasEventDate;                                                       //@synthesize hasEventDate=_hasEventDate - In the implementation block
@property (nonatomic,retain) NSDate * date;                                                           //@synthesize date=_date - In the implementation block
@property (nonatomic,retain) NSDate * endDate;                                                        //@synthesize endDate=_endDate - In the implementation block
@property (nonatomic,retain) NSDate * recencyDate;                                                    //@synthesize recencyDate=_recencyDate - In the implementation block
@property (assign,nonatomic) long long dateFormatStyle;                                               //@synthesize dateFormatStyle=_dateFormatStyle - In the implementation block
@property (assign,nonatomic) BOOL dateIsAllDay;                                                       //@synthesize dateIsAllDay=_dateIsAllDay - In the implementation block
@property (nonatomic,retain) NSTimeZone * timeZone;                                                   //@synthesize timeZone=_timeZone - In the implementation block
@property (assign,nonatomic) BOOL clearable;                                                          //@synthesize clearable=_clearable - In the implementation block
@property (assign,nonatomic) BOOL turnsOnDisplay;                                                     //@synthesize turnsOnDisplay=_turnsOnDisplay - In the implementation block
@property (nonatomic,copy) NSArray * additionalAttachments;                                           //@synthesize additionalAttachments=_additionalAttachments - In the implementation block
@property (assign,nonatomic) BOOL wantsFullscreenPresentation;                                        //@synthesize wantsFullscreenPresentation=_wantsFullscreenPresentation - In the implementation block
@property (assign,nonatomic) BOOL ignoresQuietMode;                                                   //@synthesize ignoresQuietMode=_ignoresQuietMode - In the implementation block
@property (assign,nonatomic) BOOL ignoresDowntime;                                                    //@synthesize ignoresDowntime=_ignoresDowntime - In the implementation block
@property (nonatomic,copy) NSString * unlockActionLabelOverride;                                      //@synthesize unlockActionLabelOverride=_unlockActionLabelOverride - In the implementation block
@property (nonatomic,copy) BBAction * defaultAction;
@property (nonatomic,copy) BBAction * alternateAction;
@property (nonatomic,copy) BBAction * acknowledgeAction;
@property (nonatomic,copy) BBAction * snoozeAction;
@property (nonatomic,copy) BBAction * raiseAction;
@property (nonatomic,copy) NSArray * buttons;                                                         //@synthesize buttons=_buttons - In the implementation block
@property (nonatomic,retain) NSMutableDictionary * actions;                                           //@synthesize actions=_actions - In the implementation block
@property (nonatomic,retain) NSMutableDictionary * supplementaryActionsByLayout;                      //@synthesize supplementaryActionsByLayout=_supplementaryActionsByLayout - In the implementation block
@property (nonatomic,copy) NSSet * alertSuppressionContexts;                                          //@synthesize alertSuppressionContexts=_alertSuppressionContexts - In the implementation block
@property (assign,nonatomic) BOOL expiresOnPublisherDeath;                                            //@synthesize expiresOnPublisherDeath=_expiresOnPublisherDeath - In the implementation block
@property (nonatomic,retain) NSDictionary * context;                                                  //@synthesize context=_context - In the implementation block
@property (assign,nonatomic) BOOL usesExternalSync;                                                   //@synthesize usesExternalSync=_usesExternalSync - In the implementation block
@property (nonatomic,copy) NSString * bulletinID;                                                     //@synthesize bulletinID=_bulletinID - In the implementation block
@property (nonatomic,retain) NSDate * lastInterruptDate;                                              //@synthesize lastInterruptDate=_lastInterruptDate - In the implementation block
@property (nonatomic,retain) NSDate * publicationDate;                                                //@synthesize publicationDate=_publicationDate - In the implementation block
@property (nonatomic,copy) NSString * bulletinVersionID;                                              //@synthesize bulletinVersionID=_bulletinVersionID - In the implementation block
@property (nonatomic,retain) NSDate * expirationDate;                                                 //@synthesize expirationDate=_expirationDate - In the implementation block
@property (assign,nonatomic) unsigned long long expirationEvents;                                     //@synthesize expirationEvents=_expirationEvents - In the implementation block
@property (nonatomic,copy) BBAction * expireAction;
@property (assign,nonatomic) unsigned long long realertCount_deprecated;
@property (nonatomic,copy) NSSet * alertSuppressionAppIDs_deprecated;
@property (nonatomic,copy) NSString * parentSectionID;                                                //@synthesize parentSectionID=_parentSectionID - In the implementation block
@property (nonatomic,copy) NSString * universalSectionID;                                             //@synthesize universalSectionID=_universalSectionID - In the implementation block
@property (assign,nonatomic) BOOL hasPrivateContent;
@property (assign,nonatomic) long long contentPreviewSetting;                                         //@synthesize contentPreviewSetting=_contentPreviewSetting - In the implementation block
@property (assign,nonatomic) BOOL preventAutomaticRemovalFromLockScreen;                              //@synthesize preventAutomaticRemovalFromLockScreen=_preventAutomaticRemovalFromLockScreen - In the implementation block
@property (assign,nonatomic) long long lockScreenPriority;                                            //@synthesize lockScreenPriority=_lockScreenPriority - In the implementation block
@property (assign,nonatomic) long long backgroundStyle;                                               //@synthesize backgroundStyle=_backgroundStyle - In the implementation block
@property (nonatomic,copy,readonly) NSString * publisherMatchID;
@end

@interface BBServer : NSObject
-(id)_sectionInfoForSectionID:(NSString *)arg1 effective:(BOOL)arg2 ;
-(void)publishBulletin:(BBBulletin *)arg1 destinations:(NSUInteger)arg2 alwaysToLockScreen:(BOOL)arg3 ;
-(void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 ;
-(id)initWithQueue:(id)arg1 ;
-(id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 ;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 ;
@end

@interface BBObserver : NSObject
@end

@interface NCBulletinNotificationSource : NSObject
-(BBObserver*)observer;
@end

@interface SBNCNotificationDispatcher : NSObject
-(NCBulletinNotificationSource*)notificationSource;
@end

@interface UIApplication (Notifica)
-(SBNCNotificationDispatcher*)notificationDispatcher;
@end

@interface SBLockScreenManager (Notifica)

+(id)sharedInstanceIfExists;
-(UIViewController *)lockScreenViewController;

@end

@interface SBLockScreenNotificationListController : NSObject

+(id)sharedInstance;
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(unsigned long long)arg3 ;
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(unsigned long long)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(/*^block*/id)arg5 ;

@end
