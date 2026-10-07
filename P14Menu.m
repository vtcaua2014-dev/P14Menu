//
//  P14Menu.m
//  SurfVT14
//
//  Versão reorganizada e mais robusta do menu original.
//  4 módulos:
//    - LiveSplit  (código embutido, ex-LiveTimer.m)
//    - Chrono     (código embutido, ex-P14Chrono.m / FZxc)
//    - Floating Clock (código embutido, ex-FloatingTimer.m)
//    - IOSTimer      (código embutido, ex-IOSTimer.m; fonte DS-Digital embutida via DSDigital.h)
//    - FPS Counter   (novo módulo embutido: contador de FPS arrastável, independente dos outros)
//    - PiP Float     (código embutido, ex-PiPFloat.m; não liga sozinho — só via Ativar/Desativar)
//    - VTimer        (novo módulo embutido: cronômetro com botões + toques, menu de
//                      cor de fundo/cor da fonte/8 fontes/foto de fundo; não liga sozinho)
//    - Satella    (botão "Instalar": abre o link do Satella_Jailed.dylib)
//
//  Ícone SurfVT14 embutido em Base64 (P14IconBase64). Se o Base64 ficar vazio,
//  usa um SF Symbol como fallback.
//
//  Exemplo de compilação:
//  clang -arch arm64 -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
//    -miphoneos-version-min=13.0 -fobjc-arc -dynamiclib \
//    -framework UIKit -framework Foundation \
//    -framework CoreGraphics -framework QuartzCore \
//    -install_name @rpath/P14Menu.dylib -o P14Menu.dylib P14Menu.m
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <PhotosUI/PhotosUI.h>
#import <Photos/Photos.h>

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

// Módulos embutidos (código dentro deste arquivo, sem dylib externo).
@property (nonatomic, copy) void (^startBlock)(void);
@property (nonatomic, copy) void (^stopBlock)(void);

// Módulo que só abre um link (ex.: Satella leva para a instalação do dylib).
@property (nonatomic, copy) NSString *linkURL;

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

// Janelas dos módulos embutidos (o menu nunca as confunde com as de dylibs externos).
static NSHashTable<UIWindow *> *P14EmbeddedWindows(void) {
    static NSHashTable<UIWindow *> *table;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ table = [NSHashTable weakObjectsHashTable]; });
    return table;
}

#pragma mark - Módulo embutido: Chrono (ex-FZxc)

#pragma mark - Caixinha (pill) com digitos

@interface P14ChronoPill : UIView
@property (nonatomic, strong) UILabel *digits;
@property (nonatomic, strong) UILabel *suffix;
@property (nonatomic, assign) NSInteger value;
- (instancetype)initWithSuffix:(NSString *)suffix;
- (void)setValue:(NSInteger)value animated:(BOOL)animated;
@end

@implementation P14ChronoPill

- (instancetype)initWithSuffix:(NSString *)suffix {
    self = [super initWithFrame:CGRectMake(0, 0, 88, 56)];
    if (self) {
        _value = -1;
        self.backgroundColor = [UIColor colorWithRed:0.02 green:0.03 blue:0.04 alpha:1.0]; // preto
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;

        _digits = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 52, 56)];
        _digits.textAlignment = NSTextAlignmentRight;
        _digits.textColor = [UIColor whiteColor];
        _digits.font = [UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightBold];
        _digits.text = @"00";
        [self addSubview:_digits];

        _suffix = [[UILabel alloc] initWithFrame:CGRectMake(62, 0, 22, 56)];
        _suffix.textAlignment = NSTextAlignmentLeft;
        _suffix.textColor = [UIColor whiteColor];
        _suffix.font = [UIFont systemFontOfSize:26 weight:UIFontWeightLight];
        _suffix.text = suffix;
        [self addSubview:_suffix];
    }
    return self;
}

- (void)setValue:(NSInteger)value animated:(BOOL)animated {
    if (value == _value) return;
    _value = value;
    if (animated) {
        CATransition *t = [CATransition animation];
        t.type = kCATransitionPush;
        t.subtype = kCATransitionFromBottom;
        t.duration = 0.18;
        [self.digits.layer addAnimation:t forKey:@"roll"];
    }
    self.digits.text = [NSString stringWithFormat:@"%02ld", (long)value];
}

@end

#pragma mark - Overlay principal

@interface P14ChronoOverlay : NSObject
@property (nonatomic, strong) P14Window *window;
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) P14ChronoPill *hourPill, *minutePill, *secondPill;
@property (nonatomic, strong) UILabel *msLabel;
@property (nonatomic, strong) UIView *settings;
@property (nonatomic, strong) UILabel *sizeValueLabel, *roundValueLabel;
@property (nonatomic, strong) NSTimer *ticker;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval accumulated;
@property (nonatomic, strong) NSArray<UIColor *> *palette;
+ (instancetype)shared;
- (void)start;
- (void)stop;
@end

@implementation P14ChronoOverlay

+ (instancetype)shared {
    static P14ChronoOverlay *o; static dispatch_once_t once;
    dispatch_once(&once, ^{ o = [P14ChronoOverlay new]; });
    return o;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _palette = @[
            [UIColor whiteColor],
            [UIColor colorWithRed:0.20 green:0.85 blue:0.40 alpha:1],
            [UIColor colorWithRed:1.00 green:0.25 blue:0.25 alpha:1],
            [UIColor colorWithRed:0.25 green:0.60 blue:1.00 alpha:1],
            [UIColor colorWithRed:1.00 green:0.80 blue:0.10 alpha:1],
            [UIColor colorWithRed:0.65 green:0.35 blue:1.00 alpha:1]
        ];
    }
    return self;
}

#pragma mark Montagem

- (void)start {
    if (self.window) return;

    CGRect screen = [UIScreen mainScreen].bounds;
    UIWindowScene *scene = P14ForegroundWindowScene();

    self.window = scene ? [[P14Window alloc] initWithWindowScene:scene]
                        : [[P14Window alloc] initWithFrame:screen];
    self.window.frame = screen;
    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = [UIColor clearColor];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor clearColor];
    self.window.rootViewController = vc;
    self.window.hidden = NO;
    [P14EmbeddedWindows() addObject:self.window];

    self.running = NO;
    self.accumulated = 0;

    [self buildTimerInView:vc.view];
    [self buildSettingsInView:vc.view];
    [self render];
}

- (void)stop {
    [self.ticker invalidate];
    self.ticker = nil;
    self.running = NO;
    self.accumulated = 0;

    self.window.hidden = YES;
    self.window.rootViewController = nil;
    self.window = nil;
    self.container = nil;
    self.settings = nil;
    self.hourPill = nil;
    self.minutePill = nil;
    self.secondPill = nil;
    self.msLabel = nil;
}

- (void)buildTimerInView:(UIView *)root {
    CGFloat w = 88 * 3 + 8 * 2, h = 56 + 22;
    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    self.container.center = CGPointMake(root.bounds.size.width / 2, 120);
    [root addSubview:self.container];

    self.hourPill   = [[P14ChronoPill alloc] initWithSuffix:@"h"];
    self.minutePill = [[P14ChronoPill alloc] initWithSuffix:@"m"];
    self.secondPill = [[P14ChronoPill alloc] initWithSuffix:@"s"];
    NSArray *pills = @[self.hourPill, self.minutePill, self.secondPill];
    for (NSInteger i = 0; i < 3; i++) {
        P14ChronoPill *p = pills[i];
        p.frame = CGRectMake(i * (88 + 8), 0, 88, 56);
        [self.container addSubview:p];
    }

    self.msLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 58, w, 18)];
    self.msLabel.textAlignment = NSTextAlignmentCenter;
    self.msLabel.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    self.msLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightLight];
    self.msLabel.text = @"000";
    [self.container addSubview:self.msLabel];

    UITapGestureRecognizer *single = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap)];
    UITapGestureRecognizer *dbl = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap)];
    dbl.numberOfTapsRequired = 2;
    [single requireGestureRecognizerToFail:dbl];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    lp.minimumPressDuration = 0.6;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.container addGestureRecognizer:single];
    [self.container addGestureRecognizer:dbl];
    [self.container addGestureRecognizer:lp];
    [self.container addGestureRecognizer:pan];
}

#pragma mark Configuracoes

- (UILabel *)labelWithText:(NSString *)t frame:(CGRect)f {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    return l;
}

- (void)buildSettingsInView:(UIView *)root {
    CGFloat W = 290, H = 330;
    self.settings = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, H)];
    self.settings.center = CGPointMake(root.bounds.size.width / 2, root.bounds.size.height / 2);
    self.settings.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.96];
    self.settings.layer.cornerRadius = 18;
    self.settings.hidden = YES;
    [root addSubview:self.settings];

    UILabel *title = [self labelWithText:@"Timer Settings" frame:CGRectMake(16, 12, 200, 28)];
    title.font = [UIFont boldSystemFontOfSize:18];
    [self.settings addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(W - 52, 12, 40, 28);
    [close setTitle:@"OK" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.settings addSubview:close];

    // Tamanho
    [self.settings addSubview:[self labelWithText:@"Size" frame:CGRectMake(16, 52, 80, 24)]];
    self.sizeValueLabel = [self labelWithText:@"100%" frame:CGRectMake(W - 76, 52, 60, 24)];
    self.sizeValueLabel.textAlignment = NSTextAlignmentRight;
    [self.settings addSubview:self.sizeValueLabel];
    UISlider *sz = [[UISlider alloc] initWithFrame:CGRectMake(16, 80, W - 32, 30)];
    sz.minimumValue = 0.5; sz.maximumValue = 1.6; sz.value = 1.0;
    [sz addTarget:self action:@selector(sizeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.settings addSubview:sz];

    // Arredondamento
    [self.settings addSubview:[self labelWithText:@"Roundness" frame:CGRectMake(16, 120, 120, 24)]];
    self.roundValueLabel = [self labelWithText:@"10" frame:CGRectMake(W - 76, 120, 60, 24)];
    self.roundValueLabel.textAlignment = NSTextAlignmentRight;
    [self.settings addSubview:self.roundValueLabel];
    UISlider *rd = [[UISlider alloc] initWithFrame:CGRectMake(16, 148, W - 32, 30)];
    rd.minimumValue = 0; rd.maximumValue = 28; rd.value = 10;
    [rd addTarget:self action:@selector(roundChanged:) forControlEvents:UIControlEventValueChanged];
    [self.settings addSubview:rd];

    // Cor dos numeros (tag 100+i) e do fundo (tag 200+i)
    [self.settings addSubview:[self labelWithText:@"Color" frame:CGRectMake(16, 190, 120, 24)]];
    [self addSwatchRowAtY:218 tagBase:100 colors:self.palette];

    [self.settings addSubview:[self labelWithText:@"Background" frame:CGRectMake(16, 258, 140, 24)]];
    NSArray *bgs = @[
        [UIColor colorWithRed:0.02 green:0.03 blue:0.04 alpha:1],
        [UIColor colorWithWhite:0.18 alpha:1],
        [UIColor colorWithRed:0.30 green:0.20 blue:0.55 alpha:1],
        [UIColor colorWithRed:0.55 green:0.10 blue:0.10 alpha:1],
        [UIColor colorWithRed:0.08 green:0.30 blue:0.45 alpha:1],
        [UIColor colorWithWhite:0 alpha:0.35]
    ];
    [self addSwatchRowAtY:286 tagBase:200 colors:bgs];
}

- (void)addSwatchRowAtY:(CGFloat)y tagBase:(NSInteger)base colors:(NSArray<UIColor *> *)colors {
    for (NSInteger i = 0; i < (NSInteger)colors.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(16 + i * 44, y, 34, 34);
        b.backgroundColor = colors[i];
        b.layer.cornerRadius = 17;
        b.layer.borderWidth = 2;
        b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
        b.tag = base + i;
        [b addTarget:self action:@selector(swatchTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.settings addSubview:b];
    }
}

- (void)swatchTapped:(UIButton *)b {
    UIColor *c = b.backgroundColor;
    BOOL isText = b.tag < 200;
    for (P14ChronoPill *p in @[self.hourPill, self.minutePill, self.secondPill]) {
        if (isText) { p.digits.textColor = c; p.suffix.textColor = c; }
        else        { p.backgroundColor = c; }
    }
    if (isText) self.msLabel.textColor = c;
    [self haptic];
}

- (void)sizeChanged:(UISlider *)s {
    self.container.transform = CGAffineTransformMakeScale(s.value, s.value);
    self.sizeValueLabel.text = [NSString stringWithFormat:@"%d%%", (int)(s.value * 100)];
}

- (void)roundChanged:(UISlider *)s {
    for (P14ChronoPill *p in @[self.hourPill, self.minutePill, self.secondPill]) p.layer.cornerRadius = s.value;
    self.roundValueLabel.text = [NSString stringWithFormat:@"%d", (int)s.value];
}

- (void)closeSettings {
    [UIView animateWithDuration:0.2 animations:^{ self.settings.alpha = 0; }
                     completion:^(BOOL f) { self.settings.hidden = YES; self.settings.alpha = 1; }];
}

- (void)openSettings {
    self.settings.alpha = 0;
    self.settings.hidden = NO;
    [self.settings.superview bringSubviewToFront:self.settings];
    [UIView animateWithDuration:0.2 animations:^{ self.settings.alpha = 1; }];
}

#pragma mark Gestos

- (void)haptic {
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [g impactOccurred];
}

- (void)onSingleTap {
    if (self.running) [self pause]; else [self resume];
    [self haptic];
}

- (void)onDoubleTap {
    [self reset];
    [self haptic];
}

- (void)onLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) { [self haptic]; [self openSettings]; }
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *root = self.container.superview;
    CGPoint t = [g translationInView:root];
    self.container.center = CGPointMake(self.container.center.x + t.x, self.container.center.y + t.y);
    [g setTranslation:CGPointZero inView:root];
}

#pragma mark Tempo

- (CFTimeInterval)total {
    return self.accumulated + (self.running ? (CACurrentMediaTime() - self.startTime) : 0);
}

- (void)resume {
    self.running = YES;
    self.startTime = CACurrentMediaTime();
    [self.ticker invalidate];
    self.ticker = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *t) { [self render]; }];
    [[NSRunLoop mainRunLoop] addTimer:self.ticker forMode:NSRunLoopCommonModes];
}

- (void)pause {
    self.accumulated = [self total];
    self.running = NO;
    [self.ticker invalidate];
    self.ticker = nil;
    [self render];
}

- (void)reset {
    self.running = NO;
    self.accumulated = 0;
    [self.ticker invalidate];
    self.ticker = nil;
    [self render];
}

- (void)render {
    CFTimeInterval t = [self total];
    NSInteger totalMs = (NSInteger)(t * 1000.0);
    NSInteger ms = totalMs % 1000;
    NSInteger sec = (totalMs / 1000) % 60;
    NSInteger min = (totalMs / 60000) % 60;
    NSInteger hr  = (totalMs / 3600000) % 100;
    [self.hourPill setValue:hr animated:self.running];
    [self.minutePill setValue:min animated:self.running];
    [self.secondPill setValue:sec animated:self.running];
    self.msLabel.text = [NSString stringWithFormat:@"%03ld", (long)ms];
}

@end


#pragma mark - Módulo embutido: LiveSplit (ex-LiveTimer)

typedef NS_ENUM(NSInteger, P14LiveState) {
    P14LiveStateReset,
    P14LiveStateRunning,
    P14LiveStatePaused
};

// ---------- Aparência (mude aqui) ----------
static const CGFloat P14LiveBigFont    = 30.0;   // segundos / minutos
static const CGFloat P14LiveSmallFont  = 18.0;   // centésimos
static const CGFloat P14LivePadding    = 10.0;
static const CGFloat P14LiveWidth      = 130.0;
static const CGFloat P14LiveHeight     = 44.0;

static UIColor *P14LiveColorGreen(void) { return [UIColor colorWithRed:0.36 green:0.82 blue:0.42 alpha:1.0]; }
static UIColor *P14LiveColorBlue(void)  { return [UIColor colorWithRed:0.25 green:0.55 blue:0.95 alpha:1.0]; }
static UIColor *P14LiveColorGray(void)  { return [UIColor colorWithWhite:0.62 alpha:1.0]; }

// ---------- View do cronômetro ----------
@interface P14LiveView : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) P14LiveState state;
@property (nonatomic) CFTimeInterval startTime;   // instante em que começou o trecho atual
@property (nonatomic) CFTimeInterval accumulated; // tempo acumulado antes do trecho atual
@end

@implementation P14LiveView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.06 alpha:0.92];
        self.layer.cornerRadius = 6;
        self.layer.masksToBounds = YES;
        self.multipleTouchEnabled = NO;

        _label = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, P14LivePadding, 0)];
        _label.textAlignment = NSTextAlignmentRight;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.6;
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_label];

        // Dois toques (reinicia) e um toque (inicia/para).
        // Sem requireGestureRecognizerToFail: o 1º toque age na hora (sem atraso);
        // no 2º toque o duplo-toque reinicia tudo.
        UITapGestureRecognizer *doubleTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];

        UITapGestureRecognizer *singleTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        pan.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:pan];

        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        [self refresh];
    }
    return self;
}

- (CFTimeInterval)elapsed {
    if (self.state == P14LiveStateRunning) {
        return self.accumulated + (CACurrentMediaTime() - self.startTime);
    }
    return self.accumulated;
}

// ---------- Ações ----------
- (void)onSingleTap:(UITapGestureRecognizer *)g {
    if (self.state == P14LiveStateRunning) {
        self.accumulated += CACurrentMediaTime() - self.startTime;
        self.state = P14LiveStatePaused;
    } else {
        // Reset ou Pausado -> roda (retoma de onde parou)
        self.startTime = CACurrentMediaTime();
        self.state = P14LiveStateRunning;
    }
    [self refresh];
}

- (void)onDoubleTap:(UITapGestureRecognizer *)g {
    self.state = P14LiveStateReset;
    self.accumulated = 0;
    [self refresh];
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *host = self.superview;
    CGPoint t = [g translationInView:host];
    CGPoint c = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    CGRect b = host.bounds;
    c.x = MAX(CGRectGetWidth(self.bounds) / 2, MIN(c.x, CGRectGetWidth(b) - CGRectGetWidth(self.bounds) / 2));
    c.y = MAX(CGRectGetHeight(self.bounds) / 2, MIN(c.y, CGRectGetHeight(b) - CGRectGetHeight(self.bounds) / 2));
    self.center = c;
    [g setTranslation:CGPointZero inView:host];
}

// ---------- Exibição ----------
- (void)tick {
    if (self.state == P14LiveStateRunning) [self refresh];
}

- (UIColor *)currentColor {
    switch (self.state) {
        case P14LiveStateRunning: return P14LiveColorGreen();
        case P14LiveStatePaused:  return P14LiveColorBlue();
        default:             return P14LiveColorGray();
    }
}

// Formato LiveSplit: 23.57  |  1:23.57  |  1:02:03.45
- (void)refresh {
    CFTimeInterval e = [self elapsed];
    if (e < 0) e = 0;

    long long totalCs = (long long)(e * 100.0);
    long long cs = totalCs % 100;
    long long totalSec = totalCs / 100;
    long long s = totalSec % 60;
    long long m = (totalSec / 60) % 60;
    long long h = totalSec / 3600;

    NSString *big;
    if (h > 0)      big = [NSString stringWithFormat:@"%lld:%02lld:%02lld", h, m, s];
    else if (m > 0) big = [NSString stringWithFormat:@"%lld:%02lld", m, s];
    else            big = [NSString stringWithFormat:@"%lld", s];
    NSString *small = [NSString stringWithFormat:@".%02lld", cs];

    UIColor *color = [self currentColor];
    UIFont *bigFont = [UIFont systemFontOfSize:P14LiveBigFont weight:UIFontWeightBold];
    UIFont *smallFont = [UIFont systemFontOfSize:P14LiveSmallFont weight:UIFontWeightBold];
    // Algarismos de largura fixa para o texto não "tremer" ao contar
    bigFont = [UIFont monospacedDigitSystemFontOfSize:P14LiveBigFont weight:UIFontWeightBold];
    smallFont = [UIFont monospacedDigitSystemFontOfSize:P14LiveSmallFont weight:UIFontWeightBold];

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]
        initWithString:big attributes:@{NSFontAttributeName: bigFont,
                                        NSForegroundColorAttributeName: color}];
    [str appendAttributedString:[[NSAttributedString alloc]
        initWithString:small attributes:@{NSFontAttributeName: smallFont,
                                          NSForegroundColorAttributeName: color}]];
    self.label.attributedText = str;
}

- (void)invalidate {
    [self.link invalidate];
    self.link = nil;
}

@end


static P14Window *gLiveWindow;
static P14LiveView *gLiveTimer;

static void P14LiveStart(void) {
    if (gLiveWindow) return;

    CGRect screen = UIScreen.mainScreen.bounds;
    UIWindowScene *scene = P14ForegroundWindowScene();
    P14Window *w = scene ? [[P14Window alloc] initWithWindowScene:scene]
                         : [[P14Window alloc] initWithFrame:screen];

    w.frame = screen;
    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = UIColor.clearColor;
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;
    w.rootViewController = vc;

    CGFloat top = MAX(60.0, w.safeAreaInsets.top + 12.0); // abaixo do notch / ilha
    gLiveTimer = [[P14LiveView alloc] initWithFrame:CGRectMake(16, top, P14LiveWidth, P14LiveHeight)];
    [vc.view addSubview:gLiveTimer];

    w.hidden = NO;
    gLiveWindow = w;
    [P14EmbeddedWindows() addObject:w];
}

static void P14LiveStop(void) {
    [gLiveTimer invalidate];
    gLiveTimer = nil;
    gLiveWindow.hidden = YES;
    gLiveWindow.rootViewController = nil;
    gLiveWindow = nil;
}

#pragma mark - Módulo embutido: Floating Clock (ex-FloatingTimer.m)

static CGFloat P14FloatCell(NSString *ch, CGFloat digitW, NSDictionary *attrs) {
    unichar c = [ch characterAtIndex:0];
    if (c >= '0' && c <= '9') return digitW;
    return [ch sizeWithAttributes:attrs].width;
}

@interface P14FloatDigits : UIView
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIFont *font;
@end

@implementation P14FloatDigits

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    return self;
}

- (void)setText:(NSString *)text {
    if ([_text isEqualToString:text]) return;
    _text = [text copy];
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!self.text || !self.font || !self.color) return;
    NSDictionary *attrs = @{NSFontAttributeName: self.font,
                            NSForegroundColorAttributeName: self.color};

    CGFloat digitW = 0;
    for (int i = 0; i < 10; i++) {
        NSString *d = [NSString stringWithFormat:@"%d", i];
        CGFloat w = [d sizeWithAttributes:attrs].width;
        if (w > digitW) digitW = w;
    }

    CGFloat total = 0;
    for (NSUInteger i = 0; i < self.text.length; i++) {
        NSString *ch = [self.text substringWithRange:NSMakeRange(i, 1)];
        total += P14FloatCell(ch, digitW, attrs);
    }

    CGFloat scale = 1.0;
    if (total > self.bounds.size.width) {
        scale = self.bounds.size.width / total;
    }
    CGFloat lineH = self.font.lineHeight;
    CGFloat sx = (self.bounds.size.width - total * scale) / 2;
    CGFloat sy = (self.bounds.size.height - lineH * scale) / 2;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, sx, sy);
    CGContextScaleCTM(ctx, scale, scale);

    CGFloat x = 0;
    for (NSUInteger i = 0; i < self.text.length; i++) {
        NSString *ch = [self.text substringWithRange:NSMakeRange(i, 1)];
        CGFloat cw = P14FloatCell(ch, digitW, attrs);
        CGFloat w = [ch sizeWithAttributes:attrs].width;
        [ch drawAtPoint:CGPointMake(x + (cw - w) / 2, 0) withAttributes:attrs];
        x += cw;
    }
    CGContextRestoreGState(ctx);
}

@end

@interface P14FloatCard : UIView
@property (nonatomic) BOOL going;
@property (nonatomic) CFTimeInterval t0;
@property (nonatomic) CFTimeInterval banked;
@property (nonatomic) NSInteger tint;
@property (nonatomic, strong) P14FloatDigits *digits;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *resetBtn;
@property (nonatomic, strong) UIButton *tintBtn;
@property (nonatomic, strong) CADisplayLink *link;
@end

@implementation P14FloatCard

- (instancetype)initWithOrigin:(CGPoint)o {
    CGRect f = CGRectMake(o.x, o.y, 264, 104);
    self = [super initWithFrame:f];
    if (!self) return nil;

    self.backgroundColor = [UIColor blackColor];
    self.layer.cornerRadius = 14;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.45;
    self.layer.shadowRadius = 8;
    self.layer.shadowOffset = CGSizeMake(0, 3);

    self.digits =
        [[P14FloatDigits alloc] initWithFrame:CGRectMake(8, 8, 248, 52)];
    UIFont *font = [UIFont fontWithName:@"Georgia" size:40];
    if (!font) font = [UIFont systemFontOfSize:40];
    self.digits.font = font;
    [self addSubview:self.digits];

    self.playBtn = [self roundButton:@"\u25B6\uFE0E"
                                   x:71
                              action:@selector(onPlay)];
    self.resetBtn = [self roundButton:@"\u21BA"
                                    x:117
                               action:@selector(onReset)];
    self.tintBtn = [self roundButton:@"\u25CF"
                                   x:163
                              action:@selector(onTint)];

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(onDrag:)];
    [self addGestureRecognizer:pan];

    self.link =
        [CADisplayLink displayLinkWithTarget:self selector:@selector(onFrame)];
    self.link.preferredFramesPerSecond = 30;
    [self.link addToRunLoop:[NSRunLoop mainRunLoop]
                    forMode:NSRunLoopCommonModes];

    [self applyTint];
    [self redraw];
    return self;
}

- (UIButton *)roundButton:(NSString *)title x:(CGFloat)x action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(x, 66, 30, 30);
    b.layer.cornerRadius = 15;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1.0].CGColor;
    b.titleLabel.font = [UIFont systemFontOfSize:14];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:0.85 alpha:1.0]
            forState:UIControlStateNormal];
    [b addTarget:self
          action:sel
forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:b];
    return b;
}

- (UIColor *)tintColorForIndex:(NSInteger)i {
    if (i == 1) {
        return [UIColor colorWithRed:0.20 green:0.52 blue:1.0 alpha:1.0];
    }
    if (i == 2) {
        return [UIColor colorWithRed:0.55 green:0.82 blue:1.0 alpha:1.0];
    }
    return [UIColor whiteColor];
}

- (void)applyTint {
    UIColor *c = [self tintColorForIndex:self.tint];
    self.digits.color = c;
    [self.tintBtn setTitleColor:c forState:UIControlStateNormal];
}

- (CFTimeInterval)total {
    if (self.going) {
        return self.banked + (CACurrentMediaTime() - self.t0);
    }
    return self.banked;
}

- (void)onPlay {
    CFTimeInterval now = CACurrentMediaTime();
    if (self.going) {
        self.banked += now - self.t0;
        self.going = NO;
        [self.playBtn setTitle:@"\u25B6\uFE0E" forState:UIControlStateNormal];
    } else {
        self.t0 = now;
        self.going = YES;
        [self.playBtn setTitle:@"\u2759\u2759" forState:UIControlStateNormal];
    }
    [self redraw];
}

- (void)onReset {
    self.going = NO;
    self.banked = 0;
    [self.playBtn setTitle:@"\u25B6\uFE0E" forState:UIControlStateNormal];
    [self redraw];
}

- (void)onTint {
    self.tint = (self.tint + 1) % 3;
    [self applyTint];
}

- (void)onDrag:(UIPanGestureRecognizer *)g {
    UIView *host = self.superview;
    CGPoint d = [g translationInView:host];
    CGFloat hw = self.bounds.size.width / 2;
    CGFloat hh = self.bounds.size.height / 2;
    CGFloat x = self.center.x + d.x;
    CGFloat y = self.center.y + d.y;
    x = fmax(hw, fmin(x, host.bounds.size.width - hw));
    y = fmax(hh, fmin(y, host.bounds.size.height - hh));
    self.center = CGPointMake(x, y);
    [g setTranslation:CGPointZero inView:host];
}

- (void)onFrame {
    if (self.going) {
        [self redraw];
    }
}

- (void)redraw {
    CFTimeInterval e = [self total];
    if (e < 0) e = 0;
    long long tenths = (long long)(e * 10.0);
    long long d = tenths % 10;
    long long sec = tenths / 10;
    long long s = sec % 60;
    long long m = (sec / 60) % 60;
    long long h = sec / 3600;
    self.digits.text =
        [NSString stringWithFormat:@"%02lld: %02lld: %02lld. %lld",
         h, m, s, d];
}

- (void)invalidate {
    [self.link invalidate];
    self.link = nil;
}

@end


static P14Window *gFloatWindow;
static P14FloatCard *gFloatCard;

static void P14FloatStart(void) {
    if (gFloatWindow) return;

    CGRect screen = [UIScreen mainScreen].bounds;
    UIWindowScene *scene = P14ForegroundWindowScene();
    P14Window *w = scene ? [[P14Window alloc] initWithWindowScene:scene]
                         : [[P14Window alloc] initWithFrame:screen];

    w.frame = screen;
    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    w.rootViewController = vc;

    CGFloat x = (screen.size.width - 264) / 2;
    gFloatCard = [[P14FloatCard alloc] initWithOrigin:CGPointMake(x, 70)];
    [vc.view addSubview:gFloatCard];

    w.hidden = NO;
    gFloatWindow = w;
    [P14EmbeddedWindows() addObject:w];
}

static void P14FloatStop(void) {
    [gFloatCard invalidate];
    gFloatCard = nil;
    gFloatWindow.hidden = YES;
    gFloatWindow.rootViewController = nil;
    gFloatWindow = nil;
}


#pragma mark - Módulo embutido: DS Digital (ex-IOSTimer.m)

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

#include "DSDigital.h"
#define P14_DSDIGITAL_HAS_FONT 1

#pragma mark - Cores (bicolor) e fonte

static UIColor *P14DSDigitalGray(void)      { return [UIColor colorWithWhite:0.25 alpha:1.0]; }
static UIColor *P14DSDigitalLightGray(void) { return [UIColor colorWithWhite:0.50 alpha:1.0]; }

static NSString *gP14DSDigitalFontName = nil;

static NSData *P14DSDigitalFontData(void) {
#ifdef P14_DSDIGITAL_HAS_FONT
    return [NSData dataWithBytes:DSDigital_ttf length:DSDigital_ttf_len];
#else
    NSArray *names = @[@"DS-DIGI", @"DS-Digital", @"DSDigital", @"DS-DIGIB"];
    NSArray *exts  = @[@"ttf", @"TTF", @"otf"];
    NSMutableArray *dirs = [NSMutableArray array];
    [dirs addObject:NSBundle.mainBundle.resourcePath ?: @""];
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (docs) [dirs addObject:docs];
    for (NSString *dir in dirs) {
        for (NSString *n in names) {
            for (NSString *e in exts) {
                NSString *path = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", n, e]];
                NSData *d = [NSData dataWithContentsOfFile:path];
                if (d.length) return d;
            }
        }
    }
    return nil;
#endif
}

static void P14DSDigitalLoadFont(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSData *data = P14DSDigitalFontData();
        if (!data.length) return;
        CGDataProviderRef prov = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        if (!prov) return;
        CGFontRef font = CGFontCreateWithDataProvider(prov);
        CGDataProviderRelease(prov);
        if (!font) return;
        CFErrorRef err = NULL;
        CTFontManagerRegisterGraphicsFont(font, &err); // erro = já registrada, tudo bem
        if (err) CFRelease(err);
        NSString *ps = (__bridge_transfer NSString *)CGFontCopyPostScriptName(font);
        if (ps.length) gP14DSDigitalFontName = ps;
        CGFontRelease(font);
    });
}

static NSString *const kP14DSDigitalModeKey = @"P14DSDigital.mode";

typedef NS_ENUM(NSInteger, P14DSDigitalMode) {
    P14DSDigitalModeBox = 0,
    P14DSDigitalModeBar = 1,
};

typedef NS_ENUM(NSInteger, P14DSDigitalState) {
    P14DSDigitalStateIdle = 0,    // zerado, parado
    P14DSDigitalStateRunning = 1, // contando
    P14DSDigitalStatePaused = 2,  // pausado
};

#pragma mark - Janela que deixa o toque passar

@interface P14DSDigitalWindow : UIWindow
@end

@implementation P14DSDigitalWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    if (v == self || v == self.rootViewController.view) {
        return nil; // toques fora do cronômetro vão para o app
    }
    return v;
}
@end

#pragma mark - View do cronômetro

@interface P14DSDigitalView : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *modeButton;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) P14DSDigitalState state;
@property (nonatomic, assign) P14DSDigitalMode mode;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval accumulated;
@property (nonatomic, assign) CGFloat boxScale;
- (void)applyModeAnimated:(BOOL)animated;
- (void)clampAnimated:(BOOL)animated;
@end

@implementation P14DSDigitalView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _boxScale = 1.0;
        _mode = (P14DSDigitalMode)[[NSUserDefaults standardUserDefaults] integerForKey:kP14DSDigitalModeKey];
        if (_mode != P14DSDigitalModeBar) _mode = P14DSDigitalModeBox;

        self.layer.borderWidth = 1.5;

        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = UIColor.whiteColor;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.4;
        _label.text = [self formatted:0];
        [self addSubview:_label];

        _modeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _modeButton.tintColor = [UIColor colorWithWhite:1 alpha:0.75];
        BOOL hasImage = NO;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:13
                                                                weight:UIImageSymbolWeightSemibold];
            UIImage *img = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath"
                                   withConfiguration:cfg];
            if (img) {
                [_modeButton setImage:img forState:UIControlStateNormal];
                hasImage = YES;
            }
        }
        if (!hasImage) {
            [_modeButton setTitle:@"⇄" forState:UIControlStateNormal];
            _modeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
            [_modeButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.75]
                              forState:UIControlStateNormal];
        }
        [_modeButton addTarget:self action:@selector(onModeButton)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_modeButton];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:tap];

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:pan];

        UIPinchGestureRecognizer *pinch =
            [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
        [self addGestureRecognizer:pinch];

        [self refreshAppearance];
    }
    return self;
}

// No modelo Barra o texto passa da barra: aumenta a área de toque
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect r = self.bounds;
    if (self.mode == P14DSDigitalModeBar) r = CGRectInset(r, 0, -14);
    return CGRectContainsPoint(r, point);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (self.mode == P14DSDigitalModeBox) {
        self.label.frame = CGRectMake(10, 24, w - 20, h - 30);
        self.modeButton.frame = CGRectMake(w - 36, 2, 34, 34);
    } else {
        self.label.frame = CGRectMake(46, -9, w - 92, 38);
        self.modeButton.frame = CGRectMake(w - 46, -12, 44, 44);
    }
}

#pragma mark Aparência / modelo

- (UIFont *)timerFontOfSize:(CGFloat)size {
    P14DSDigitalLoadFont();
    UIFont *f = gP14DSDigitalFontName ? [UIFont fontWithName:gP14DSDigitalFontName size:size] : nil;
    if (!f) f = [UIFont monospacedDigitSystemFontOfSize:size weight:UIFontWeightBold];
    return f;
}

- (void)refreshAppearance {
    // Bicolor: fundo cinza, fontes brancas
    self.backgroundColor = P14DSDigitalGray();
    self.label.textColor = UIColor.whiteColor;
    if (self.mode == P14DSDigitalModeBox) {
        self.layer.cornerRadius = 26;
        self.label.font = [self timerFontOfSize:58];
    } else {
        self.layer.cornerRadius = 10;
        self.label.font = [self timerFontOfSize:32];
    }
    [self refreshStateColors];
}

- (void)refreshStateColors {
    switch (self.state) {
        case P14DSDigitalStateRunning:   // borda branca, texto cheio
            self.layer.borderColor = UIColor.whiteColor.CGColor;
            self.label.alpha = 1.0;
            break;
        case P14DSDigitalStatePaused:    // borda cinza, texto esmaecido
            self.layer.borderColor = P14DSDigitalLightGray().CGColor;
            self.label.alpha = 0.55;
            break;
        default:                     // zerado
            self.layer.borderColor = P14DSDigitalLightGray().CGColor;
            self.label.alpha = 1.0;
            break;
    }
}

- (NSString *)posKey:(NSString *)axis mode:(P14DSDigitalMode)m {
    return [NSString stringWithFormat:@"P14DSDigital.pos%@.%ld", axis, (long)m];
}

- (void)savePosition {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d setDouble:self.center.x forKey:[self posKey:@"X" mode:self.mode]];
    [d setDouble:self.center.y forKey:[self posKey:@"Y" mode:self.mode]];
}

- (void)applyModeAnimated:(BOOL)animated {
    UIView *host = self.superview;
    CGRect hb = host ? host.bounds : UIScreen.mainScreen.bounds;

    CGSize size;
    CGAffineTransform tf;
    if (self.mode == P14DSDigitalModeBox) {
        size = CGSizeMake(190, 100);
        tf = CGAffineTransformMakeScale(self.boxScale, self.boxScale);
    } else {
        size = CGSizeMake(MAX(200, hb.size.width - 36), 20);
        tf = CGAffineTransformIdentity;
    }

    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    NSString *kx = [self posKey:@"X" mode:self.mode];
    NSString *ky = [self posKey:@"Y" mode:self.mode];
    CGPoint c;
    if ([d objectForKey:kx] && [d objectForKey:ky]) {
        c = CGPointMake([d doubleForKey:kx], [d doubleForKey:ky]);
    } else if (self.mode == P14DSDigitalModeBox) {
        c = CGPointMake(20 + 95, hb.size.height - 200);
    } else {
        c = CGPointMake(hb.size.width / 2.0, hb.size.height - 140);
    }

    void (^changes)(void) = ^{
        self.transform = CGAffineTransformIdentity;
        self.bounds = CGRectMake(0, 0, size.width, size.height);
        self.center = c;
        self.transform = tf;
        [self refreshAppearance];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    };

    if (animated) {
        [UIView animateWithDuration:0.25 animations:changes];
    } else {
        changes();
    }
    [self clampAnimated:animated];
}

- (void)onModeButton {
    UIImpactFeedbackGenerator *h =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [h impactOccurred];

    [self savePosition];
    self.mode = (self.mode == P14DSDigitalModeBox) ? P14DSDigitalModeBar : P14DSDigitalModeBox;
    [[NSUserDefaults standardUserDefaults] setInteger:self.mode forKey:kP14DSDigitalModeKey];
    [self applyModeAnimated:YES];
}

#pragma mark Tempo

- (CFTimeInterval)elapsed {
    return self.accumulated +
           (self.state == P14DSDigitalStateRunning ? (CACurrentMediaTime() - self.startTime) : 0);
}

- (NSString *)formatted:(CFTimeInterval)t {
    long total = (long)llround(t * 1000.0);
    if (total < 0) total = 0;
    long ms = total % 1000;
    long s  = (total / 1000) % 60;
    long m  = (total / 60000) % 60;
    long h  = total / 3600000;
    if (h > 0) {
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld.%03ld", h, m, s, ms];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld.%03ld", m, s, ms];
}

- (void)tick {
    self.label.text = [self formatted:[self elapsed]];
}

- (void)start {
    self.state = P14DSDigitalStateRunning;
    self.startTime = CACurrentMediaTime();
    [self.link invalidate];
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    [self refreshStateColors];
}

- (void)pause {
    self.accumulated += CACurrentMediaTime() - self.startTime;
    self.state = P14DSDigitalStatePaused;
    [self.link invalidate];
    self.link = nil;
    [self tick];
    [self refreshStateColors];
}

- (void)reset {
    [self.link invalidate];
    self.link = nil;
    self.accumulated = 0;
    self.state = P14DSDigitalStateIdle;
    [self tick];
    [self refreshStateColors];
}

#pragma mark Gestos

// 1º toque inicia, 2º pausa, 3º reinicia
- (void)onTap:(UITapGestureRecognizer *)g {
    UIImpactFeedbackGenerator *h =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [h impactOccurred];
    switch (self.state) {
        case P14DSDigitalStateIdle:    [self start]; break;
        case P14DSDigitalStateRunning: [self pause]; break;
        case P14DSDigitalStatePaused:  [self reset]; break;
    }
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *host = self.superview;
    if (!host) return;
    CGPoint t = [g translationInView:host];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:host];

    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        [self clampAnimated:YES];
        [self savePosition];
    }
}

- (void)onPinch:(UIPinchGestureRecognizer *)g {
    if (self.mode != P14DSDigitalModeBox) return;
    CGFloat s = MAX(0.5, MIN(self.boxScale * g.scale, 2.0));
    if (g.state == UIGestureRecognizerStateChanged) {
        self.transform = CGAffineTransformMakeScale(s, s);
    } else if (g.state == UIGestureRecognizerStateEnded ||
               g.state == UIGestureRecognizerStateCancelled) {
        self.boxScale = s;
        self.transform = CGAffineTransformMakeScale(s, s);
        [self clampAnimated:YES];
        [self savePosition];
    }
}

- (void)clampAnimated:(BOOL)animated {
    UIView *host = self.superview;
    if (!host) return;
    CGRect b = host.bounds;
    UIEdgeInsets in = host.safeAreaInsets;
    CGFloat halfW = self.frame.size.width / 2.0;
    CGFloat halfH = self.frame.size.height / 2.0;
    CGFloat minX = halfW, maxX = b.size.width - halfW;
    CGFloat minY = in.top + halfH, maxY = b.size.height - in.bottom - halfH;
    CGPoint c = self.center;
    c.x = MAX(minX, MIN(c.x, MAX(minX, maxX)));
    c.y = MAX(minY, MIN(c.y, MAX(minY, maxY)));
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{ self.center = c; }];
    } else {
        self.center = c;
    }
}

@end

#pragma mark - Controle da janela
static P14DSDigitalWindow *gP14DSDigitalWindow = nil;
static P14DSDigitalView *gP14DSDigitalTimer;

static UIWindowScene *P14DSDigitalFindScene(void) API_AVAILABLE(ios(13.0)) {
    UIWindowScene *fallback = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)s;
        }
        if (!fallback) fallback = (UIWindowScene *)s;
    }
    return fallback;
}

static void P14DSDigitalStart(void) {
    if (gP14DSDigitalWindow) return;

    P14DSDigitalWindow *w = nil;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = P14DSDigitalFindScene();
        if (scene) w = [[P14DSDigitalWindow alloc] initWithWindowScene:scene];
    }
    if (!w) {
        w = [[P14DSDigitalWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }

    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = UIColor.clearColor;

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = UIColor.clearColor;
    w.rootViewController = vc;
    w.hidden = NO;

    P14DSDigitalView *timer = [[P14DSDigitalView alloc] initWithFrame:CGRectMake(0, 0, 190, 100)];
    [vc.view addSubview:timer];
    [vc.view layoutIfNeeded];
    [timer applyModeAnimated:NO];

    gP14DSDigitalWindow = w;
    gP14DSDigitalTimer = timer;
    [P14EmbeddedWindows() addObject:w];
}

static void P14DSDigitalStop(void) {
    [gP14DSDigitalTimer.link invalidate];
    gP14DSDigitalTimer = nil;
    gP14DSDigitalWindow.hidden = YES;
    gP14DSDigitalWindow.rootViewController = nil;
    gP14DSDigitalWindow = nil;
}


#pragma mark - Módulo embutido: FPS Counter

@interface P14FPSView : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) NSInteger frameCount;
@property (nonatomic) CFTimeInterval windowStart;
@end

@implementation P14FPSView

- (instancetype)initWithOrigin:(CGPoint)origin {
    CGRect frame = CGRectMake(origin.x, origin.y, 108.0, 40.0);
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.05 blue:0.12 alpha:0.92];
    self.layer.cornerRadius = 10.0;
    self.layer.borderWidth = 1.5;
    self.layer.borderColor =
        [UIColor colorWithRed:0.35 green:0.85 blue:0.95 alpha:1.0].CGColor;

    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor =
        [UIColor colorWithRed:0.45 green:0.90 blue:0.98 alpha:1.0];
    self.label.font = [UIFont monospacedDigitSystemFontOfSize:17.0
                                                        weight:UIFontWeightSemibold];
    self.label.text = @"-- FPS";
    [self addSubview:self.label];

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(onDrag:)];
    [self addGestureRecognizer:pan];

    self.windowStart = CACurrentMediaTime();
    self.link = [CADisplayLink displayLinkWithTarget:self
                                             selector:@selector(onFrame)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop
                     forMode:NSRunLoopCommonModes];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
}

- (void)onDrag:(UIPanGestureRecognizer *)gesture {
    UIView *host = self.superview;
    if (!host) return;

    CGPoint translation = [gesture translationInView:host];
    CGFloat halfWidth = self.bounds.size.width / 2.0;
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    CGFloat x = self.center.x + translation.x;
    CGFloat y = self.center.y + translation.y;

    x = fmax(halfWidth, fmin(x, host.bounds.size.width - halfWidth));
    y = fmax(halfHeight, fmin(y, host.bounds.size.height - halfHeight));

    self.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointZero inView:host];
}

- (void)onFrame {
    self.frameCount += 1;

    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval elapsed = now - self.windowStart;

    if (elapsed >= 0.5) {
        double fps = (double)self.frameCount / elapsed;
        self.label.text = [NSString stringWithFormat:@"%d FPS", (int)llround(fps)];
        self.frameCount = 0;
        self.windowStart = now;
    }
}

- (void)invalidate {
    [self.link invalidate];
    self.link = nil;
}

@end

static P14Window *gFPSWindow;
static P14FPSView *gFPSView;

static void P14FPSStart(void) {
    if (gFPSWindow) return;

    CGRect screen = [UIScreen mainScreen].bounds;
    UIWindowScene *scene = P14ForegroundWindowScene();
    P14Window *w = scene ? [[P14Window alloc] initWithWindowScene:scene]
                         : [[P14Window alloc] initWithFrame:screen];

    w.frame = screen;
    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    w.rootViewController = vc;

    CGPoint origin = CGPointMake(16.0, w.safeAreaInsets.top + 16.0);
    gFPSView = [[P14FPSView alloc] initWithOrigin:origin];
    [vc.view addSubview:gFPSView];

    w.hidden = NO;
    gFPSWindow = w;
    [P14EmbeddedWindows() addObject:w];
}

static void P14FPSStop(void) {
    [gFPSView invalidate];
    gFPSView = nil;
    gFPSWindow.hidden = YES;
    gFPSWindow.rootViewController = nil;
    gFPSWindow = nil;
}

#pragma mark - Módulo embutido: PiP Float (ex-PiPFloat.m)


typedef NS_ENUM(NSInteger, P14PipMode) {
    P14PipModeSquare = 0,   // foto 1: quadrado com milissegundos
    P14PipModeWide,         // foto 2: retângulo médio
    P14PipModePill,         // foto 3: pílula pequena
    P14PipModeCount
};

#pragma mark - Janela que deixa os toques passarem

@interface P14PipWindow : UIWindow
@end

@implementation P14PipWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    if (v == self || v == self.rootViewController.view) return nil;
    return v;
}
@end

#pragma mark - PiP Float

@interface P14PipFloat : NSObject
@property (nonatomic, strong) P14PipWindow *window;
@property (nonatomic, strong) UIView *holder;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *modeButton;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) P14PipMode mode;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval accumulated;
+ (instancetype)shared;
- (void)setup;
@end

static const CGFloat kP14PipPad = 12.0;

@implementation P14PipFloat

+ (instancetype)shared {
    static P14PipFloat *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [P14PipFloat new]; });
    return s;
}

- (CGSize)cardSizeForMode:(P14PipMode)m {
    switch (m) {
        case P14PipModeSquare: return CGSizeMake(120, 120);
        case P14PipModeWide:   return CGSizeMake(200, 58);
        default:           return CGSizeMake(150, 38);
    }
}

- (CGFloat)radiusForMode:(P14PipMode)m {
    switch (m) {
        case P14PipModeSquare: return 30;
        case P14PipModeWide:   return 22;
        default:           return 19;
    }
}

- (CGFloat)fontSizeForMode:(P14PipMode)m {
    switch (m) {
        case P14PipModeSquare: return 24;
        case P14PipModeWide:   return 28;
        default:           return 22;
    }
}

- (UIWindowScene *)activeScene API_AVAILABLE(ios(13.0)) {
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if ([sc isKindOfClass:UIWindowScene.class] &&
            sc.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)sc;
        }
    }
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if ([sc isKindOfClass:UIWindowScene.class]) return (UIWindowScene *)sc;
    }
    return nil;
}

- (void)setup {
    if (self.window) return;

    UIWindowScene *scene = [self activeScene];
    if (!scene) return;

    self.window = [[P14PipWindow alloc] initWithWindowScene:scene];
    self.window.frame = scene.coordinateSpace.bounds;
    self.window.windowLevel = UIWindowLevelAlert + 100;
    self.window.backgroundColor = UIColor.clearColor;
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;
    self.window.rootViewController = vc;
    self.window.hidden = NO;
    [P14EmbeddedWindows() addObject:self.window];

    CGSize cs = [self cardSizeForMode:self.mode];
    CGRect screen = self.window.bounds;

    self.holder = [[UIView alloc] initWithFrame:CGRectMake((screen.size.width - cs.width) / 2.0,
                                                           90,
                                                           cs.width + kP14PipPad,
                                                           cs.height + kP14PipPad)];
    [vc.view addSubview:self.holder];

    // Cartão branco
    self.card = [[UIView alloc] initWithFrame:CGRectMake(0, kP14PipPad, cs.width, cs.height)];
    self.card.backgroundColor = UIColor.whiteColor;
    self.card.layer.cornerRadius = [self radiusForMode:self.mode];
    if (@available(iOS 13.0, *)) self.card.layer.cornerCurve = kCACornerCurveContinuous;
    self.card.layer.shadowColor = UIColor.blackColor.CGColor;
    self.card.layer.shadowOpacity = 0.3;
    self.card.layer.shadowRadius = 6;
    self.card.layer.shadowOffset = CGSizeMake(0, 2);
    [self.holder addSubview:self.card];

    // Texto
    self.label = [[UILabel alloc] initWithFrame:CGRectInset(self.card.bounds, 6, 4)];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor colorWithRed:0.11 green:0.15 blue:0.26 alpha:1.0];
    self.label.adjustsFontSizeToFitWidth = YES;
    self.label.minimumScaleFactor = 0.4;
    self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.label.userInteractionEnabled = NO;
    [self.card addSubview:self.label];

    // Botão de trocar modo
    self.modeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.modeButton.frame = CGRectMake(cs.width + kP14PipPad - 26, 0, 26, 26);
    self.modeButton.backgroundColor = [UIColor colorWithRed:0.72 green:0.24 blue:0.85 alpha:1.0];
    self.modeButton.layer.cornerRadius = 13;
    self.modeButton.tintColor = UIColor.whiteColor;
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"rectangle.on.rectangle"];
        [self.modeButton setImage:img forState:UIControlStateNormal];
    } else {
        [self.modeButton setTitle:@"⇄" forState:UIControlStateNormal];
    }
    [self.modeButton addTarget:self action:@selector(changeMode) forControlEvents:UIControlEventTouchUpInside];
    [self.holder addSubview:self.modeButton];

    // Gestos: 1 toque = iniciar/pausar, 2 toques = reiniciar
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [self.card addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.card addGestureRecognizer:singleTap];

    // Arrastar
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.holder addGestureRecognizer:pan];

    // Atualização da tela
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    if (@available(iOS 10.0, *)) self.link.preferredFramesPerSecond = 30;
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    self.link.paused = YES;

    [self applyModeAnimated:NO];
    [self refresh];
}

#pragma mark - Cronômetro

- (CFTimeInterval)elapsed {
    return self.running ? self.accumulated + (CACurrentMediaTime() - self.startTime) : self.accumulated;
}

- (void)start {
    if (self.running) return;
    self.startTime = CACurrentMediaTime();
    self.running = YES;
    self.link.paused = NO;
}

- (void)pause {
    if (!self.running) return;
    self.accumulated += CACurrentMediaTime() - self.startTime;
    self.running = NO;
    self.link.paused = YES;
    [self refresh];
}

- (void)reset {
    self.running = NO;
    self.accumulated = 0;
    self.link.paused = YES;
    [self refresh];
}

- (void)teardown {
    [self.link invalidate];
    self.link = nil;
    self.window.hidden = YES;
    self.window.rootViewController = nil;
    self.window = nil;
    self.holder = nil;
    self.card = nil;
    self.label = nil;
    self.modeButton = nil;
}

- (void)tick { [self refresh]; }

- (void)refresh {
    CFTimeInterval e = [self elapsed];
    NSInteger totalMs = (NSInteger)(e * 1000.0);
    NSInteger ms = totalMs % 1000;
    NSInteger s  = (totalMs / 1000) % 60;
    NSInteger m  = (totalMs / 60000) % 60;
    NSInteger h  = totalMs / 3600000;

    if (self.mode == P14PipModeSquare) {
        self.label.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld.%03ld", (long)h, (long)m, (long)s, (long)ms];
    } else {
        self.label.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    }
}

#pragma mark - Modos

- (void)changeMode {
    self.mode = (self.mode + 1) % P14PipModeCount;
    [self applyModeAnimated:YES];
    [self refresh];
}

- (void)applyModeAnimated:(BOOL)animated {
    CGSize cs = [self cardSizeForMode:self.mode];
    CGFloat radius = [self radiusForMode:self.mode];
    UIFont *font;
    if (@available(iOS 13.0, *)) {
        font = [UIFont monospacedDigitSystemFontOfSize:[self fontSizeForMode:self.mode] weight:UIFontWeightHeavy];
    } else {
        font = [UIFont boldSystemFontOfSize:[self fontSizeForMode:self.mode]];
    }

    // Mantém o canto superior direito no mesmo lugar ao trocar de tamanho
    CGRect old = self.holder.frame;
    CGFloat right = CGRectGetMaxX(old);
    CGRect newFrame = CGRectMake(right - (cs.width + kP14PipPad), old.origin.y, cs.width + kP14PipPad, cs.height + kP14PipPad);

    void (^changes)(void) = ^{
        self.holder.frame = newFrame;
        self.card.frame = CGRectMake(0, kP14PipPad, cs.width, cs.height);
        self.card.layer.cornerRadius = radius;
        self.label.frame = CGRectInset(self.card.bounds, 6, 4);
        self.label.font = font;
        self.modeButton.frame = CGRectMake(cs.width + kP14PipPad - 26, 0, 26, 26);
    };

    if (animated) {
        [UIView animateWithDuration:0.25 animations:changes];
    } else {
        changes();
    }
}

#pragma mark - Gestos

- (void)haptic {
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [g impactOccurred];
}

- (void)onSingleTap {
    [self haptic];
    if (self.running) [self pause]; else [self start];
}

- (void)onDoubleTap {
    [self haptic];
    [self reset];
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *root = self.window.rootViewController.view;
    CGPoint t = [g translationInView:root];
    CGPoint c = CGPointMake(self.holder.center.x + t.x, self.holder.center.y + t.y);
    CGSize b = root.bounds.size;
    c.x = MAX(self.holder.bounds.size.width / 2.0, MIN(b.width - self.holder.bounds.size.width / 2.0, c.x));
    c.y = MAX(self.holder.bounds.size.height / 2.0, MIN(b.height - self.holder.bounds.size.height / 2.0, c.y));
    self.holder.center = c;
    [g setTranslation:CGPointZero inView:root];
}

@end

#pragma mark - Módulo embutido: VTimer

#include "TitanOne.h"

// Registra a Titan One embutida (Titan-One-400.ttf) uma única vez, para que
// [UIFont fontWithName:@"TitanOne" ...] funcione de verdade no VTimer.
static void P14VTimerLoadTitanOneFont(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSData *data = [NSData dataWithBytes:TitanOne_ttf length:TitanOne_ttf_len];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        if (!provider) return;
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        CGDataProviderRelease(provider);
        if (!font) return;
        CFErrorRef err = NULL;
        CTFontManagerRegisterGraphicsFont(font, &err); // erro = já registrada, tudo bem
        if (err) CFRelease(err);
        CGFontRelease(font);
    });
}

// Paleta de fundo (padrão: preto) e paleta de fonte (padrão: branco), com
// cores diferentes entre as duas listas para não ficarem iguais por engano.
static UIColor *P14VTimerBackgroundColor(NSInteger index) {
    switch (index) {
        case 1:  return [UIColor whiteColor];
        case 2:  return [UIColor colorWithRed:0.07 green:0.10 blue:0.22 alpha:1.0]; // azul-marinho
        case 3:  return [UIColor colorWithRed:0.55 green:0.05 blue:0.09 alpha:1.0]; // vinho
        default: return [UIColor blackColor];
    }
}

static UIColor *P14VTimerFontColor(NSInteger index) {
    switch (index) {
        case 1:  return [UIColor blackColor];
        case 2:  return [UIColor colorWithRed:0.30 green:0.95 blue:0.55 alpha:1.0]; // verde-limão
        case 3:  return [UIColor colorWithRed:1.00 green:0.80 blue:0.10 alpha:1.0]; // dourado
        default: return [UIColor whiteColor];
    }
}

// 8 fontes selecionáveis. Lilita One e Titan One só aparecem de verdade se o
// .ttf delas estiver embutido no app (mesmo esquema do DSDigital.h); sem
// isso, caem numa fonte do sistema parecida, para nunca ficar sem desenhar.
static NSString *const kP14VTimerFontNames[8] = {
    @"LilitaOne-Regular",
    @"TitanOne",
    @"AvenirNext-Heavy",
    @"Futura-Bold",
    @"Menlo-Bold",
    @"CourierNewPS-BoldMT",
    @"AmericanTypewriter-Bold",
    @"ChalkboardSE-Bold",
};

static NSString *const kP14VTimerFontLabels[8] = {
    @"Lilita One",
    @"Titan One",
    @"Avenir Next",
    @"Futura",
    @"Menlo",
    @"Courier New",
    @"Typewriter",
    @"Chalkboard",
};

static UIFont *P14VTimerFontAtIndex(NSInteger index, CGFloat size) {
    NSString *name = kP14VTimerFontNames[(NSUInteger)index % 8];
    UIFont *font = [UIFont fontWithName:name size:size];
    if (font) return font;

    // Fallback: fonte do sistema com peso parecido, caso o .ttf da fonte
    // escolhida não esteja embutido no binário.
    if (@available(iOS 13.0, *)) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightHeavy];
    }
    return [UIFont boldSystemFontOfSize:size];
}

@interface P14VTimerSwatch : UIButton
@property (nonatomic, assign) NSInteger optionIndex;
@end
@implementation P14VTimerSwatch
@end

@interface P14VTimerCard : UIView <PHPickerViewControllerDelegate,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate>

@property (nonatomic, strong) UILabel *clockLabel;
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UIButton *startPauseButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *gearButton;
@property (nonatomic, strong) UIView *settingsPanel;

@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval accumulated;

@property (nonatomic, assign) NSInteger backgroundIndex;
@property (nonatomic, assign) NSInteger fontColorIndex;
@property (nonatomic, assign) NSInteger fontIndex;

@end

@implementation P14VTimerCard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundIndex = 0; // preto
    self.fontColorIndex = 0;  // branco
    self.fontIndex = 1;       // Titan One (embutida; Lilita One ainda cai no fallback)

    self.layer.cornerRadius = 20.0;
    if (@available(iOS 13.0, *)) self.layer.cornerCurve = kCACornerCurveContinuous;
    self.clipsToBounds = YES;
    self.layer.borderWidth = 1.5;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;

    self.photoView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.photoView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoView.clipsToBounds = YES;
    self.photoView.hidden = YES;
    self.photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.photoView];

    self.clockLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 10, frame.size.width - 16, 44)];
    self.clockLabel.text = @"00:00:00";
    self.clockLabel.textAlignment = NSTextAlignmentCenter;
    self.clockLabel.adjustsFontSizeToFitWidth = YES;
    self.clockLabel.minimumScaleFactor = 0.5;
    self.clockLabel.userInteractionEnabled = NO;
    [self addSubview:self.clockLabel];

    self.startPauseButton = [self makeButtonWithTitle:@"Iniciar"];
    self.startPauseButton.frame = CGRectMake(8, 60, (frame.size.width - 24) / 2.0, 34);
    [self.startPauseButton addTarget:self action:@selector(tapStartPause) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.startPauseButton];

    self.resetButton = [self makeButtonWithTitle:@"Reiniciar"];
    self.resetButton.frame = CGRectMake(CGRectGetMaxX(self.startPauseButton.frame) + 8,
                                        60,
                                        (frame.size.width - 24) / 2.0,
                                        34);
    [self.resetButton addTarget:self action:@selector(tapReset) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.resetButton];

    self.gearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.gearButton.frame = CGRectMake(frame.size.width - 30, 2, 28, 28);
    self.gearButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    self.gearButton.layer.cornerRadius = 14;
    self.gearButton.tintColor = UIColor.whiteColor;
    if (@available(iOS 13.0, *)) {
        [self.gearButton setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
    } else {
        [self.gearButton setTitle:@"⚙" forState:UIControlStateNormal];
    }
    [self.gearButton addTarget:self action:@selector(toggleSettings) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.gearButton];

    // Sistema de toques: 1 toque inicia/pausa, 2 toques rápidos reinicia.
    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReset)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapStartPause)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:singleTap];

    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    self.link.paused = YES;

    [self applyAppearance];
    [self refreshClock];
    [self refreshButtons];

    return self;
}

- (UIButton *)makeButtonWithTitle:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    b.layer.cornerRadius = 10;
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    return b;
}

#pragma mark Cronômetro

- (CFTimeInterval)elapsed {
    return self.running ? self.accumulated + (CACurrentMediaTime() - self.startTime) : self.accumulated;
}

- (void)tapStartPause {
    if (self.running) {
        self.accumulated += CACurrentMediaTime() - self.startTime;
        self.running = NO;
        self.link.paused = YES;
    } else {
        self.startTime = CACurrentMediaTime();
        self.running = YES;
        self.link.paused = NO;
    }
    [self refreshButtons];
    [self refreshClock];
}

- (void)tapReset {
    self.running = NO;
    self.accumulated = 0;
    self.link.paused = YES;
    [self refreshButtons];
    [self refreshClock];
}

- (void)tick { [self refreshClock]; }

- (void)refreshClock {
    NSInteger total = (NSInteger)[self elapsed];
    NSInteger s = total % 60;
    NSInteger m = (total / 60) % 60;
    NSInteger h = total / 3600;
    self.clockLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
}

- (void)refreshButtons {
    [self.startPauseButton setTitle:(self.running ? @"Pausar" : @"Iniciar") forState:UIControlStateNormal];
}

#pragma mark Aparência (cores, fonte e foto)

- (void)applyAppearance {
    if (!self.photoView.image) {
        self.backgroundColor = P14VTimerBackgroundColor(self.backgroundIndex);
    } else {
        self.backgroundColor = UIColor.clearColor;
    }

    UIColor *fontColor = P14VTimerFontColor(self.fontColorIndex);
    self.clockLabel.textColor = fontColor;
    self.clockLabel.font = P14VTimerFontAtIndex(self.fontIndex, 30);

    [self.startPauseButton setTitleColor:fontColor forState:UIControlStateNormal];
    [self.resetButton setTitleColor:fontColor forState:UIControlStateNormal];
}

- (void)setBackgroundIndex:(NSInteger)backgroundIndex {
    _backgroundIndex = backgroundIndex;
    self.photoView.image = nil;
    self.photoView.hidden = YES;
    [self applyAppearance];
}

- (void)setFontColorIndex:(NSInteger)fontColorIndex {
    _fontColorIndex = fontColorIndex;
    [self applyAppearance];
}

- (void)setFontIndex:(NSInteger)fontIndex {
    _fontIndex = fontIndex;
    [self applyAppearance];
}

#pragma mark Painel de configurações

- (void)toggleSettings {
    if (self.settingsPanel) {
        [self.settingsPanel removeFromSuperview];
        self.settingsPanel = nil;
        return;
    }

    UIView *host = self.superview;
    if (!host) return;

    CGFloat width = 250.0;
    CGFloat height = 300.0;
    CGFloat originX = MIN(MAX(0, self.center.x - width / 2.0), host.bounds.size.width - width);
    CGFloat originY = CGRectGetMaxY(self.frame) + 10.0;
    if (originY + height > host.bounds.size.height) {
        originY = CGRectGetMinY(self.frame) - height - 10.0;
    }

    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(originX, originY, width, height)];
    panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    panel.layer.cornerRadius = 16;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    self.settingsPanel = panel;
    [host addSubview:panel];

    CGFloat y = 10.0;

    y = [self addSectionTitle:@"Fundo" toPanel:panel atY:y];
    y = [self addSwatchRowToPanel:panel atY:y isBackground:YES];

    y += 6;
    y = [self addSectionTitle:@"Fonte (cor)" toPanel:panel atY:y];
    y = [self addSwatchRowToPanel:panel atY:y isBackground:NO];

    y += 6;
    y = [self addSectionTitle:@"Fonte (estilo)" toPanel:panel atY:y];
    y = [self addFontGridToPanel:panel atY:y];

    y += 6;
    UIButton *photoBtn = [self makeButtonWithTitle:@"Escolher foto de fundo"];
    photoBtn.backgroundColor = [UIColor colorWithRed:0.20 green:0.50 blue:0.95 alpha:1.0];
    photoBtn.frame = CGRectMake(14, y, width - 28, 34);
    [photoBtn addTarget:self action:@selector(pickPhoto) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:photoBtn];
    y += 42;

    UIButton *clearBtn = [self makeButtonWithTitle:@"Remover foto"];
    clearBtn.frame = CGRectMake(14, y, width - 28, 30);
    [clearBtn addTarget:self action:@selector(clearPhoto) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:clearBtn];

    panel.frame = CGRectMake(panel.frame.origin.x, panel.frame.origin.y, width, y + 40);
}

- (CGFloat)addSectionTitle:(NSString *)text toPanel:(UIView *)panel atY:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(14, y, panel.bounds.size.width - 28, 18)];
    l.text = text;
    l.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    l.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [panel addSubview:l];
    return y + 20;
}

- (CGFloat)addSwatchRowToPanel:(UIView *)panel atY:(CGFloat)y isBackground:(BOOL)isBackground {
    CGFloat size = 34.0;
    CGFloat spacing = 12.0;
    CGFloat totalWidth = size * 4 + spacing * 3;
    CGFloat startX = (panel.bounds.size.width - totalWidth) / 2.0;

    for (NSInteger i = 0; i < 4; i++) {
        P14VTimerSwatch *swatch = [P14VTimerSwatch buttonWithType:UIButtonTypeCustom];
        swatch.frame = CGRectMake(startX + i * (size + spacing), y, size, size);
        swatch.backgroundColor = isBackground ? P14VTimerBackgroundColor(i) : P14VTimerFontColor(i);
        swatch.layer.cornerRadius = size / 2.0;
        swatch.layer.borderWidth = 2.0;
        swatch.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        swatch.optionIndex = i;
        [swatch addTarget:self
                   action:(isBackground ? @selector(tapBackgroundSwatch:) : @selector(tapFontColorSwatch:))
         forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:swatch];
    }

    return y + size + 10;
}

- (CGFloat)addFontGridToPanel:(UIView *)panel atY:(CGFloat)y {
    CGFloat width = (panel.bounds.size.width - 14 * 2 - 8) / 2.0;
    CGFloat height = 30.0;

    for (NSInteger i = 0; i < 8; i++) {
        NSInteger col = i % 2;
        NSInteger row = i / 2;
        UIButton *b = [self makeButtonWithTitle:kP14VTimerFontLabels[i]];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        b.tag = i;
        b.frame = CGRectMake(14 + col * (width + 8), y + row * (height + 6), width, height);
        [b addTarget:self action:@selector(tapFontButton:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:b];
    }

    return y + 4 * (height + 6) + 4;
}

- (void)tapBackgroundSwatch:(P14VTimerSwatch *)sender {
    self.backgroundIndex = sender.optionIndex;
}

- (void)tapFontColorSwatch:(P14VTimerSwatch *)sender {
    self.fontColorIndex = sender.optionIndex;
}

- (void)tapFontButton:(UIButton *)sender {
    self.fontIndex = sender.tag;
}

#pragma mark Foto de fundo

- (UIViewController *)hostViewController {
    UIResponder *responder = self;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:UIViewController.class]) return (UIViewController *)responder;
    }
    return nil;
}

- (void)pickPhoto {
    UIViewController *host = [self hostViewController];
    if (!host) return;

    if (@available(iOS 14.0, *)) {
        PHPickerConfiguration *config =
            [[PHPickerConfiguration alloc] init];
        config.filter = [PHPickerFilter imagesFilter];
        config.selectionLimit = 1;

        PHPickerViewController *picker =
            [[PHPickerViewController alloc] initWithConfiguration:config];
        picker.delegate = self;
        [host presentViewController:picker animated:YES completion:nil];
    } else {
        // iOS 13: exige NSPhotoLibraryUsageDescription no Info.plist do app
        // hospedeiro; sem isso o sistema recusa o acesso.
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [host presentViewController:picker animated:YES completion:nil];
    }
}

- (void)clearPhoto {
    self.photoView.image = nil;
    self.photoView.hidden = YES;
    [self applyAppearance];
}

- (void)setPickedImage:(UIImage *)image {
    if (!image) return;
    self.photoView.image = image;
    self.photoView.hidden = NO;
    [self applyAppearance];
}

- (void)picker:(PHPickerViewController *)picker
    didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
    [picker dismissViewControllerAnimated:YES completion:nil];

    PHPickerResult *result = results.firstObject;
    if (!result) return;

    __weak P14VTimerCard *weakSelf = self;
    [result.itemProvider loadObjectOfClass:UIImage.class
                          completionHandler:^(UIImage *image, NSError *error) {
        if (!image) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setPickedImage:image];
        });
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self setPickedImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Arrastar

- (void)onPan:(UIPanGestureRecognizer *)gesture {
    UIView *host = self.superview;
    if (!host) return;

    CGPoint translation = [gesture translationInView:host];
    CGFloat halfWidth = self.bounds.size.width / 2.0;
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    CGFloat x = self.center.x + translation.x;
    CGFloat y = self.center.y + translation.y;

    x = fmax(halfWidth, fmin(x, host.bounds.size.width - halfWidth));
    y = fmax(halfHeight, fmin(y, host.bounds.size.height - halfHeight));

    self.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointZero inView:host];

    if (self.settingsPanel) {
        [self.settingsPanel removeFromSuperview];
        self.settingsPanel = nil;
    }
}

- (void)invalidate {
    [self.link invalidate];
    self.link = nil;
    [self.settingsPanel removeFromSuperview];
    self.settingsPanel = nil;
}

@end

static P14Window *gVTimerWindow;
static P14VTimerCard *gVTimerCard;

static void P14VTimerStart(void) {
    if (gVTimerWindow) return;

    P14VTimerLoadTitanOneFont();

    CGRect screen = UIScreen.mainScreen.bounds;
    UIWindowScene *scene = P14ForegroundWindowScene();
    P14Window *w = scene ? [[P14Window alloc] initWithWindowScene:scene]
                         : [[P14Window alloc] initWithFrame:screen];

    w.frame = screen;
    w.windowLevel = UIWindowLevelAlert + 100;
    w.backgroundColor = UIColor.clearColor;

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = UIColor.clearColor;
    w.rootViewController = vc;

    CGFloat cardWidth = 230.0;
    CGFloat cardHeight = 100.0;
    CGRect cardFrame = CGRectMake((screen.size.width - cardWidth) / 2.0, 140, cardWidth, cardHeight);

    P14VTimerCard *card = [[P14VTimerCard alloc] initWithFrame:cardFrame];
    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:card action:@selector(onPan:)];
    [card addGestureRecognizer:pan];
    [vc.view addSubview:card];

    w.hidden = NO;
    gVTimerWindow = w;
    gVTimerCard = card;
    [P14EmbeddedWindows() addObject:w];
}

static void P14VTimerStop(void) {
    [gVTimerCard invalidate];
    gVTimerCard = nil;
    gVTimerWindow.hidden = YES;
    gVTimerWindow.rootViewController = nil;
    gVTimerWindow = nil;
}


#pragma mark - Atribuição de janelas por dylib

// Verdadeiro se o dylib com esse nome já está carregado no processo
// (por exemplo, quando foi injetado e abriu junto com o app).
static BOOL P14ImageLoaded(NSString *file) {
    uint32_t count = _dyld_image_count();

    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);

        if (!name) {
            continue;
        }

        NSString *last = [[NSString stringWithUTF8String:name] lastPathComponent];

        if ([last caseInsensitiveCompare:file] == NSOrderedSame) {
            return YES;
        }
    }

    return NO;
}

static BOOL P14ClassFromFile(Class cls, NSString *file) {
    if (!cls) {
        return NO;
    }

    const char *image = class_getImageName(cls);

    if (!image) {
        return NO;
    }

    NSString *last = [[NSString stringWithUTF8String:image] lastPathComponent];
    return [last caseInsensitiveCompare:file] == NSOrderedSame;
}

static BOOL P14ViewTreeFromFile(UIView *view, NSString *file, int depth) {
    if (!view) {
        return NO;
    }

    if (P14ClassFromFile(object_getClass(view), file)) {
        return YES;
    }

    if (depth <= 0) {
        return NO;
    }

    for (UIView *sub in view.subviews) {
        if (P14ViewTreeFromFile(sub, file, depth - 1)) {
            return YES;
        }
    }

    return NO;
}

// Descobre se uma janela foi criada por um dylib específico, olhando a
// classe da janela, do view controller e das views (só em janelas acima
// do nível normal, para nunca esconder a janela do jogo).
static BOOL P14WindowFromFile(UIWindow *window, NSString *file) {
    if (!window) {
        return NO;
    }

    if (P14ClassFromFile(object_getClass(window), file)) {
        return YES;
    }

    UIViewController *root = window.rootViewController;

    if (root) {
        if (P14ClassFromFile(object_getClass(root), file)) {
            return YES;
        }

        if (root.isViewLoaded &&
            P14ClassFromFile(object_getClass(root.view), file)) {
            return YES;
        }
    }

    if (window.windowLevel > UIWindowLevelNormal) {
        return P14ViewTreeFromFile(window, file, 3);
    }

    return NO;
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

    // Dylibs que já abriram junto com o app ficam escondidos até "Ativar".
    [menu startPreloadedScan];

    [menu showToast:@"Made by player14sbs" duration:3.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.clearColor;

    // LiveSplit, Chrono e Floating Clock/iOSTimer são embutidos (sem dylib externo).
    P14Module *liveSplit = P14MakeModule(@"LiveSplit", nil, YES, NO);
    liveSplit.startBlock = ^{ P14LiveStart(); };
    liveSplit.stopBlock = ^{ P14LiveStop(); };

    P14Module *chrono = P14MakeModule(@"Chrono", nil, YES, NO);
    chrono.startBlock = ^{ [[P14ChronoOverlay shared] start]; };
    chrono.stopBlock = ^{ [[P14ChronoOverlay shared] stop]; };

    P14Module *floatingClock = P14MakeModule(@"Floating Clock", nil, YES, NO);
    floatingClock.startBlock = ^{ P14FloatStart(); };
    floatingClock.stopBlock = ^{ P14FloatStop(); };

    P14Module *dsDigital = P14MakeModule(@"IOSTimer", nil, YES, NO);
    dsDigital.startBlock = ^{ P14DSDigitalStart(); };
    dsDigital.stopBlock = ^{ P14DSDigitalStop(); };

    // Satella: ao tocar, abre o link de instalação do Satella_Jailed.dylib.
    P14Module *satella = P14MakeModule(@"Satella", nil, NO, YES);
    satella.linkURL = @"https://www.mediafire.com/file/r6pc9jvtbcpy782/Satella_Jailed.dylib/file";

    P14Module *fpsCounter = P14MakeModule(@"FPS Counter", nil, NO, NO);
    fpsCounter.startBlock = ^{ P14FPSStart(); };
    fpsCounter.stopBlock = ^{ P14FPSStop(); };

    // PiP Float: cronômetro flutuante próprio (1 toque pausa/retoma, 2 toques
    // reinicia, botão roxo troca de modo). É independente dos outros — não
    // entra na exclusividade e não liga sozinho.
    P14Module *pipFloat = P14MakeModule(@"PiP Float", nil, NO, NO);
    pipFloat.startBlock = ^{ [[P14PipFloat shared] setup]; [[P14PipFloat shared] start]; };
    pipFloat.stopBlock = ^{
        [[P14PipFloat shared] pause];
        [[P14PipFloat shared] reset];
        [[P14PipFloat shared] teardown];
    };

    // VTimer: cronômetro próprio com botões Iniciar/Pausar e Reiniciar, mais
    // o sistema de toques (1 toque inicia/pausa, 2 toques rápidos reinicia),
    // e um menu de aparência (cor de fundo, cor da fonte, 8 fontes, foto de
    // fundo). Independente dos outros — não liga sozinho.
    P14Module *vtimer = P14MakeModule(@"VTimer", nil, NO, NO);
    vtimer.startBlock = ^{ P14VTimerStart(); };
    vtimer.stopBlock = ^{ P14VTimerStop(); };

    self.modules = @[liveSplit, chrono, satella, floatingClock, dsDigital, fpsCounter, pipFloat, vtimer];

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

    footer.text = @"discord.gg/mJdd7a5kv";
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

    if (module.linkURL.length > 0) {
        NSURL *url = [NSURL URLWithString:module.linkURL];

        if (url) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        } else {
            [self showToast:@"Link inválido." duration:2.5];
        }

        return;
    }

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

        if (module.linkURL.length > 0) {
            [button setTitle:@"Instalar"
                    forState:UIControlStateNormal];

            button.backgroundColor =
                [UIColor colorWithRed:0.20
                                green:0.50
                                 blue:0.95
                                alpha:1.0];

            button.enabled = YES;
        } else if (module.onlyActivate && module.active) {
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

            [self deactivateModule:other];
        }
    }

    if (module.startBlock) {
        module.startBlock();
        module.loaded = YES;
        module.active = YES;
        return;
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

    if (module.stopBlock) {
        module.stopBlock();
        module.loaded = NO;
    }

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
    if (module.loaded) {
        return YES;
    }

    if (module.file.length == 0) {
        [self showToast:@"Arquivo do módulo inválido." duration:3.0];
        return NO;
    }

    NSSet<UIWindow *> *baseline = P14AllWindows();

    // Se o dylib já foi carregado (injetado), não precisa de dlopen.
    if (P14ImageLoaded(module.file)) {
        module.loaded = YES;
        [self beginWindowScanForModule:module baseline:baseline];
        return YES;
    }

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

            [claimed addObjectsFromArray:P14EmbeddedWindows().allObjects];

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

            // Atribuição precisa: janelas cujas classes pertencem ao dylib.
            for (UIWindow *window in P14AllWindows()) {
                if (window == self.window) {
                    continue;
                }

                if (P14WindowFromFile(window, module.file)) {
                    [module.windows addObject:window];
                }
            }

            [self applyVisibilityToModule:module];
        });
    }
}

#pragma mark Dylibs já carregados

- (void)startPreloadedScan {
    __weak P14Menu *weakSelf = self;

    for (NSInteger i = 0; i < 100; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(0.2 * i * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{

            P14Menu *self = weakSelf;

            if (!self) {
                return;
            }

            for (P14Module *module in self.modules) {
                if (module.startBlock ||
                    module.file.length == 0 ||
                    !P14ImageLoaded(module.file)) {
                    continue;
                }

                module.loaded = YES;

                for (UIWindow *window in P14AllWindows()) {
                    if (window == self.window) {
                        continue;
                    }

                    if (P14WindowFromFile(window, module.file)) {
                        [module.windows addObject:window];
                    }
                }

                [self applyVisibilityToModule:module];
            }
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
