//
//  P14Menu.m
//  SurfVT14
//
//  Versão reorganizada e mais robusta do menu original.
//  Mantém os 4 módulos:
//    - LiveTimer.dylib
//    - FZxc.dylib
//    - Unlock_all.dylib
//    - FloatingTimer.dylib
//
//  Ícone SurfVT14 embutido em Base64 (P14IconBase64). Se o Base64 ficar vazio,
//  usa um SF Symbol como fallback.
//
//  Exemplo de compilação:
//  clang -arch arm64 -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
//    -miphoneos-version-min=13.0 -fobjc-arc -dynamiclib \
//    -framework UIKit -framework Foundation \
//    -install_name @rpath/P14Menu.dylib -o P14Menu.dylib P14Menu.m
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - Configuração

static NSString *const P14IconBase64 = @"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";

static NSString *const P14IconPositionXKey = @"P14Menu.IconPositionX";
static NSString *const P14IconPositionYKey = @"P14Menu.IconPositionY";

static const CGFloat P14IconSize = 56.0;
static const CGFloat P14PanelWidth = 300.0;
static const CGFloat P14RowHeight = 52.0;
static const NSTimeInterval P14WindowScanDuration = 6.0;
static const NSTimeInterval P14WindowScanInterval = 0.10;

#pragma mark - Janela pass-through

@interface P14Window : UIWindow
@end

@implementation P14Window

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];

    // Permite que toques fora dos controles do menu cheguem ao jogo.
    if (hit == self || hit == self.rootViewController.view) {
        return nil;
    }

    return hit;
}

@end

#pragma mark - Módulo

@interface P14Module : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *file;
@property (nonatomic, assign) BOOL exclusive;
@property (nonatomic, assign) BOOL onlyActivate;

@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) BOOL active;

@property (nonatomic, strong) NSHashTable<UIWindow *> *windows;
@property (nonatomic, weak) UIButton *button;

// Mantemos o handle enquanto o processo estiver vivo.
// Isso evita perder a referência ao dylib e deixa explícito que não
// tentamos fazer dlclose em módulos que podem ter hooks ativos.
@property (nonatomic, assign) void *handle;

@end

@implementation P14Module

- (instancetype)init {
    self = [super init];
    if (self) {
        _windows = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

@end

static P14Module *P14MakeModule(NSString *title,
                                 NSString *file,
                                 BOOL exclusive,
                                 BOOL onlyActivate) {
    P14Module *module = [P14Module new];
    module.title = title;
    module.file = file;
    module.exclusive = exclusive;
    module.onlyActivate = onlyActivate;
    return module;
}

#pragma mark - Utilidades

static NSSet<UIWindow *> *P14AllWindows(void) {
    NSMutableSet<UIWindow *> *windows = [NSMutableSet set];
    UIApplication *application = UIApplication.sharedApplication;

    // Compatibilidade com apps que ainda expõem UIApplication.windows.
    for (UIWindow *window in application.windows) {
        if (window) {
            [windows addObject:window];
        }
    }

    // Caminho recomendado em apps com UIScene.
    for (UIScene *scene in application.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window) {
                [windows addObject:window];
            }
        }
    }

    return windows;
}

static UIWindowScene *P14ForegroundWindowScene(void) {
    UIApplication *application = UIApplication.sharedApplication;

    // Primeiro tenta uma cena realmente ativa.
    for (UIScene *scene in application.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }

    // Depois aceita uma cena em foreground inativo.
    for (UIScene *scene in application.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        if (scene.activationState == UISceneActivationStateForegroundInactive) {
            return (UIWindowScene *)scene;
        }
    }

    return nil;
}

#pragma mark - Menu

@interface P14Menu : UIViewController

@property (nonatomic, strong) NSArray<P14Module *> *modules;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UIVisualEffectView *panel;
@property (nonatomic, strong) UILabel *toast;
@property (nonatomic, strong) P14Window *window;

@property (nonatomic, assign) BOOL panelVisible;
@property (nonatomic, assign) BOOL isBooting;

@end

static __weak P14Menu *gMenu;

@implementation P14Menu

#pragma mark Inicialização

+ (void)bootAttempt:(NSInteger)attempt {
    if (gMenu || attempt > 120) {
        return;
    }

    UIWindowScene *scene = P14ForegroundWindowScene();

    if (!scene) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self bootAttempt:attempt + 1];
        });
        return;
    }

    P14Menu *menu = [P14Menu new];

    P14Window *window = [[P14Window alloc] initWithWindowScene:scene];
    window.windowLevel = UIWindowLevelAlert + 1000.0;
    window.backgroundColor = UIColor.clearColor;
    window.opaque = NO;
    window.rootViewController = menu;
    window.hidden = NO;

    menu.window = window;
    gMenu = menu;

    [menu showToast:@"Made by player14sbs" duration:3.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.clearColor;

    self.modules = @[
        P14MakeModule(@"LiveSplit", @"LiveTimer.dylib", YES, NO),
        P14MakeModule(@"Chrono", @"FZxc.dylib", YES, NO),
        P14MakeModule(@"Satella", @"Unlock_all.dylib", NO, YES),
        P14MakeModule(@"Floating Clock/iOSTimer", @"FloatingTimer.dylib", YES, NO)
    ];

    [self buildIcon];
    [self buildPanel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self clampIcon];
    [self refreshButtons];
}

#pragma mark Ícone

- (void)buildIcon {
    UIImage *image = nil;

    if (P14IconBase64.length > 0) {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:P14IconBase64
                                                            options:0];
        if (data.length > 0) {
            image = [UIImage imageWithData:data];
        }
    }

    // Fallback leve se o Base64 não estiver definido.
    if (!image) {
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"gamecontroller.fill"];
        }
    }

    self.icon = [[UIImageView alloc] initWithImage:image];
    self.icon.frame = [self restoredIconFrame];

    self.icon.contentMode = UIViewContentModeScaleAspectFill;
    self.icon.clipsToBounds = YES;
    self.icon.userInteractionEnabled = YES;
    self.icon.backgroundColor = [UIColor colorWithWhite:0.10 alpha:0.95];

    self.icon.layer.cornerRadius = 14.0;
    self.icon.layer.borderWidth = 2.0;
    self.icon.layer.borderColor = UIColor.whiteColor.CGColor;

    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tapIcon)];

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panIcon:)];

    [self.icon addGestureRecognizer:tap];
    [self.icon addGestureRecognizer:pan];

    [self.view addSubview:self.icon];
}

- (CGRect)restoredIconFrame {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    BOOL hasX = [defaults objectForKey:P14IconPositionXKey] != nil;
    BOOL hasY = [defaults objectForKey:P14IconPositionYKey] != nil;

    if (hasX && hasY) {
        CGFloat x = [defaults doubleForKey:P14IconPositionXKey];
        CGFloat y = [defaults doubleForKey:P14IconPositionYKey];

        return CGRectMake(x, y, P14IconSize, P14IconSize);
    }

    return CGRectMake(20.0, 90.0, P14IconSize, P14IconSize);
}

- (void)saveIconPosition {
    if (!self.icon) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setDouble:self.icon.frame.origin.x
                 forKey:P14IconPositionXKey];
    [defaults setDouble:self.icon.frame.origin.y
                 forKey:P14IconPositionYKey];
}

- (void)clampIcon {
    if (!self.icon) {
        return;
    }

    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGRect safeBounds = UIEdgeInsetsInsetRect(self.view.bounds, safeInsets);

    // Garante que o botão continue acessível mesmo após rotação,
    // mudança de tamanho ou abertura em outra cena.
    CGRect frame = self.icon.frame;

    frame.origin.x = MAX(CGRectGetMinX(safeBounds),
                         MIN(CGRectGetMinX(frame),
                             CGRectGetMaxX(safeBounds) - CGRectGetWidth(frame)));

    frame.origin.y = MAX(CGRectGetMinY(safeBounds),
                         MIN(CGRectGetMinY(frame),
                             CGRectGetMaxY(safeBounds) - CGRectGetHeight(frame)));

    self.icon.frame = frame;
}

- (void)panIcon:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;

    CGPoint translation = [gesture translationInView:self.view];

    view.center = CGPointMake(view.center.x + translation.x,
                              view.center.y + translation.y);

    [gesture setTranslation:CGPointZero inView:self.view];

    if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled) {

        [self clampIcon];
        [self saveIconPosition];
    }
}

- (void)tapIcon {
    self.panelVisible = !self.panelVisible;

    [self updatePanelVisibilityAnimated:YES];
}

#pragma mark Painel

- (void)buildPanel {
    CGFloat rowTop = 50.0;
    CGFloat footerHeight = 34.0;
    CGFloat panelHeight =
        rowTop + (P14RowHeight * self.modules.count) + footerHeight;

    UIBlurEffect *effect =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    self.panel = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.panel.frame = CGRectMake(0.0,
                                  0.0,
                                  P14PanelWidth,
                                  panelHeight);

    self.panel.layer.cornerRadius = 18.0;
    self.panel.layer.borderWidth = 1.5;
    self.panel.layer.borderColor =
        [UIColor colorWithRed:1.0
                        green:0.75
                         blue:0.10
                        alpha:0.80].CGColor;

    self.panel.clipsToBounds = YES;
    self.panel.alpha = 0.0;
    self.panel.hidden = YES;

    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(0.0,
                                                  10.0,
                                                  P14PanelWidth,
                                                  30.0)];

    title.text = @"SurfVT14";
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor =
        [UIColor colorWithRed:1.0
                        green:0.85
                         blue:0.20
                        alpha:1.0];

    title.font = [UIFont systemFontOfSize:20.0
                                   weight:UIFontWeightHeavy];

    [self.panel.contentView addSubview:title];

    for (NSUInteger i = 0; i < self.modules.count; i++) {
        P14Module *module = self.modules[i];

        CGFloat y = rowTop + (P14RowHeight * i);

        UILabel *label =
            [[UILabel alloc] initWithFrame:CGRectMake(16.0,
                                                      y,
                                                      170.0,
                                                      P14RowHeight)];

        label.text = module.title;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont systemFontOfSize:16.0
                                       weight:UIFontWeightSemibold];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.70;

        [self.panel.contentView addSubview:label];

        UIButton *button =
            [UIButton buttonWithType:UIButtonTypeSystem];

        button.frame =
            CGRectMake(P14PanelWidth - 106.0,
                       y + 9.0,
                       90.0,
                       34.0);

        button.tag = (NSInteger)i;
        button.layer.cornerRadius = 10.0;

        button.titleLabel.font =
            [UIFont systemFontOfSize:14.0
                              weight:UIFontWeightBold];

        [button setTitleColor:UIColor.whiteColor
                     forState:UIControlStateNormal];

        [button addTarget:self
                   action:@selector(tapModule:)
         forControlEvents:UIControlEventTouchUpInside];

        module.button = button;

        [self.panel.contentView addSubview:button];
    }

    UILabel *footer =
        [[UILabel alloc] initWithFrame:CGRectMake(0.0,
                                                  panelHeight - 30.0,
                                                  P14PanelWidth,
                                                  22.0)];

    footer.text = @"Made by player14sbs";
    footer.textAlignment = NSTextAlignmentCenter;
    footer.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    footer.font = [UIFont systemFontOfSize:12.0
                                    weight:UIFontWeightMedium];

    [self.panel.contentView addSubview:footer];
    [self.view addSubview:self.panel];

    [self refreshButtons];
}

- (void)updatePanelVisibilityAnimated:(BOOL)animated {
    if (self.panelVisible) {
        [self.view bringSubviewToFront:self.panel];
        self.panel.hidden = NO;

        if (!animated) {
            self.panel.alpha = 1.0;
            return;
        }

        self.panel.alpha = 0.0;
        self.panel.transform = CGAffineTransformMakeScale(0.94, 0.94);

        [UIView animateWithDuration:0.18
                         animations:^{
            self.panel.alpha = 1.0;
            self.panel.transform = CGAffineTransformIdentity;
        }];
    } else {
        if (!animated) {
            self.panel.alpha = 0.0;
            self.panel.hidden = YES;
            return;
        }

        [UIView animateWithDuration:0.15
                         animations:^{
            self.panel.alpha = 0.0;
            self.panel.transform =
                CGAffineTransformMakeScale(0.96, 0.96);
        }
                         completion:^(BOOL finished) {
            if (!self.panelVisible) {
                self.panel.hidden = YES;
                self.panel.transform = CGAffineTransformIdentity;
            }
        }];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.panel) {
        self.panel.center =
            CGPointMake(CGRectGetMidX(self.view.bounds),
                        CGRectGetMidY(self.view.bounds));
    }

    [self clampIcon];
}

#pragma mark Toast

- (void)showToast:(NSString *)text duration:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toast.layer removeAllAnimations];
        [self.toast removeFromSuperview];
        self.toast = nil;

        UILabel *label = [UILabel new];

        label.text = [NSString stringWithFormat:@"  %@  ", text];
        label.textColor = UIColor.whiteColor;
        label.backgroundColor =
            [UIColor colorWithWhite:0.05 alpha:0.90];

        label.font = [UIFont systemFontOfSize:15.0
                                        weight:UIFontWeightBold];

        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.layer.cornerRadius = 14.0;
        label.clipsToBounds = YES;

        CGFloat maxWidth =
            MAX(100.0, self.view.bounds.size.width - 40.0);

        CGSize size =
            [label sizeThatFits:CGSizeMake(maxWidth, 200.0)];

        CGFloat width = MIN(size.width, maxWidth);
        CGFloat height = size.height + 16.0;

        CGFloat top = self.view.safeAreaInsets.top + 12.0;

        label.frame =
            CGRectMake((self.view.bounds.size.width - width) / 2.0,
                       top,
                       width,
                       height);

        label.alpha = 0.0;
        label.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin;

        [self.view addSubview:label];
        self.toast = label;

        [UIView animateWithDuration:0.20
                         animations:^{
            label.alpha = 1.0;
        }];

        __weak UILabel *weakLabel = label;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(duration * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UILabel *strongLabel = weakLabel;

            if (!strongLabel) {
                return;
            }

            [UIView animateWithDuration:0.30
                             animations:^{
                strongLabel.alpha = 0.0;
            }
                             completion:^(BOOL finished) {
                [strongLabel removeFromSuperview];
            }];
        });
    });
}

#pragma mark Módulos

- (void)tapModule:(UIButton *)button {
    NSInteger index = button.tag;

    if (index < 0 || index >= (NSInteger)self.modules.count) {
        return;
    }

    P14Module *module = self.modules[index];

    if (module.onlyActivate) {
        if (!module.active) {
            [self activateModule:module];
        }
    } else if (module.active) {
        [self deactivateModule:module];
    } else {
        [self activateModule:module];
    }

    [self refreshButtons];
}

- (void)refreshButtons {
    for (P14Module *module in self.modules) {
        UIButton *button = module.button;

        if (!button) {
            continue;
        }

        if (module.onlyActivate && module.active) {
            [button setTitle:@"Ativado"
                    forState:UIControlStateNormal];

            button.backgroundColor =
                [UIColor colorWithWhite:0.35 alpha:1.0];

            button.enabled = NO;
        } else if (module.active) {
            [button setTitle:@"Desativar"
                    forState:UIControlStateNormal];

            button.backgroundColor =
                [UIColor colorWithRed:0.85
                                green:0.20
                                 blue:0.20
                                alpha:1.0];

            button.enabled = YES;
        } else {
            [button setTitle:@"Ativar"
                    forState:UIControlStateNormal];

            button.backgroundColor =
                [UIColor colorWithRed:0.15
                                green:0.65
                                 blue:0.30
                                alpha:1.0];

            button.enabled = YES;
        }
    }
}

- (void)applyVisibilityToModule:(P14Module *)module {
    if (!module) {
        return;
    }

    for (UIWindow *window in module.windows.allObjects) {
        if (!window) {
            continue;
        }

        window.hidden = !module.active;
    }
}

- (void)activateModule:(P14Module *)module {
    if (!module) {
        return;
    }

    // Módulos exclusivos não podem ficar ativos simultaneamente.
    if (module.exclusive) {
        for (P14Module *other in self.modules) {
            if (other == module ||
                !other.exclusive ||
                !other.active) {
                continue;
            }

            other.active = NO;
            [self applyVisibilityToModule:other];
        }
    }

    if (!module.loaded && ![self loadModule:module]) {
        return;
    }

    module.active = YES;
    [self applyVisibilityToModule:module];
}

- (void)deactivateModule:(P14Module *)module {
    if (!module) {
        return;
    }

    module.active = NO;
    [self applyVisibilityToModule:module];
}

#pragma mark Carregamento

- (NSArray<NSString *> *)candidatePathsForFile:(NSString *)file {
    NSBundle *mainBundle = NSBundle.mainBundle;
    NSMutableArray<NSString *> *paths = [NSMutableArray array];

    if (mainBundle.privateFrameworksPath.length > 0) {
        [paths addObject:
         [mainBundle.privateFrameworksPath
          stringByAppendingPathComponent:file]];
    }

    if (mainBundle.bundlePath.length > 0) {
        [paths addObject:
         [mainBundle.bundlePath
          stringByAppendingPathComponent:file]];

        [paths addObject:
         [[mainBundle.bundlePath
           stringByAppendingPathComponent:@"Frameworks"]
          stringByAppendingPathComponent:file]];
    }

    Dl_info info = {0};

    if (dladdr((const void *)&P14AllWindows, &info) &&
        info.dli_fname != NULL) {

        NSString *loadedPath =
            [NSString stringWithUTF8String:info.dli_fname];

        if (loadedPath.length > 0) {
            NSString *directory =
                [loadedPath stringByDeletingLastPathComponent];

            [paths addObject:
             [directory stringByAppendingPathComponent:file]];
        }
    }

    [paths addObject:
     [@"/Library/MobileSubstrate/DynamicLibraries"
      stringByAppendingPathComponent:file]];

    // Remove duplicatas preservando a ordem.
    NSMutableOrderedSet *unique =
        [NSMutableOrderedSet orderedSetWithArray:paths];

    return unique.array;
}

- (BOOL)loadModule:(P14Module *)module {
    if (module.loaded && module.handle) {
        return YES;
    }

    if (module.file.length == 0) {
        [self showToast:@"Arquivo do módulo inválido." duration:3.0];
        return NO;
    }

    NSSet<UIWindow *> *baseline = P14AllWindows();

    void *handle = NULL;
    NSString *loadedPath = nil;

    for (NSString *path in [self candidatePathsForFile:module.file]) {
        if (![NSFileManager.defaultManager
              fileExistsAtPath:path]) {
            continue;
        }

        dlerror();

        handle = dlopen(path.fileSystemRepresentation,
                        RTLD_NOW | RTLD_GLOBAL);

        if (handle) {
            loadedPath = path;
            break;
        }
    }

    // Fallback para o loader resolver pelo nome.
    if (!handle) {
        dlerror();
        handle = dlopen(module.file.UTF8String,
                        RTLD_NOW | RTLD_GLOBAL);

        if (handle) {
            loadedPath = module.file;
        }
    }

    if (!handle) {
        const char *error = dlerror();

        NSString *message =
            [NSString stringWithFormat:
             @"Erro ao carregar %@\n%s",
             module.file,
             error ? error : "arquivo não encontrado"];

        [self showToast:message duration:5.0];
        return NO;
    }

    module.handle = handle;
    module.loaded = YES;

    // Após o dlopen, algumas bibliotecas criam janelas/overlays
    // de forma assíncrona. Fazemos uma varredura limitada no tempo.
    [self beginWindowScanForModule:module baseline:baseline];

    NSString *shortPath =
        loadedPath.lastPathComponent.length > 0
        ? loadedPath.lastPathComponent
        : module.file;

    [self showToast:
     [NSString stringWithFormat:@"%@ carregado", shortPath]
           duration:2.0];

    return YES;
}

- (void)beginWindowScanForModule:(P14Module *)module
                         baseline:(NSSet<UIWindow *> *)baseline {

    __weak P14Menu *weakSelf = self;
    __weak P14Module *weakModule = module;

    NSInteger iterations =
        (NSInteger)ceil(P14WindowScanDuration /
                        P14WindowScanInterval);

    for (NSInteger i = 0; i <= iterations; i++) {
        NSTimeInterval delay = i * P14WindowScanInterval;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{

            P14Menu *self = weakSelf;
            P14Module *module = weakModule;

            if (!self || !module) {
                return;
            }

            NSMutableSet<UIWindow *> *claimed =
                [NSMutableSet setWithSet:baseline];

            if (self.window) {
                [claimed addObject:self.window];
            }

            for (P14Module *other in self.modules) {
                if (other == module) {
                    continue;
                }

                [claimed addObjectsFromArray:
                 other.windows.allObjects];
            }

            for (UIWindow *window in P14AllWindows()) {
                if ([claimed containsObject:window]) {
                    continue;
                }

                // Não captura janelas pertencentes ao menu.
                if (window == self.window) {
                    continue;
                }

                [module.windows addObject:window];
            }

            [self applyVisibilityToModule:module];
        });
    }
}

#pragma mark Ciclo de vida

- (void)reapplyAll {
    if (!self) {
        return;
    }

    for (P14Module *module in self.modules) {
        [self applyVisibilityToModule:module];
    }

    if (self.window) {
        self.window.hidden = NO;
    }

    [self clampIcon];
}

@end

#pragma mark - Entrada

static void P14ReapplyAll(void) {
    P14Menu *menu = gMenu;

    if (!menu) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [menu reapplyAll];
    });
}

__attribute__((constructor))
static void P14Init(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [P14Menu bootAttempt:0];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                      object:nil
                       queue:NSOperationQueue.mainQueue
                  usingBlock:^(NSNotification *notification) {

            (void)notification;

            if (!gMenu) {
                [P14Menu bootAttempt:0];
                return;
            }

            // Reaplica imediatamente e após pequenos atrasos para
            // acompanhar reconstruções de UI feitas pelo app.
            P14ReapplyAll();

            NSArray<NSNumber *> *delays =
                @[@0.2, @0.6, @1.5];

            for (NSNumber *number in delays) {
                dispatch_after(
                    dispatch_time(DISPATCH_TIME_NOW,
                                  (int64_t)(number.doubleValue *
                                            NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                        P14ReapplyAll();
                    });
            }
        }];
    });
}
