import { common } from '@kit.AbilityKit'

@ObservedV2
class SplashState {
  @Trace progress: number = 0
  @Trace showPrivacyDialog: boolean = false
  @Trace isLoading: boolean = true
  @Trace isAgreed: boolean = false
  @Trace hotLaunch: boolean = false
}

@Entry
@ComponentV2
struct SplashPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: SplashState = new SplashState()
  private progressTimer: number = -1

  aboutToAppear(): void {
    // FWD-REF: P-S10-002 resolve_by=Slice 10 Step 3c — check MMKV_KEY_HAS_AGREE_AGREEMENT
    // Default: show privacy if not agreed
    this.state.showPrivacyDialog = true
    this.startProgressAnimation()
  }

  startProgressAnimation(): void {
    const steps = [0, 50, 80, 100]
    let i = 0
    this.progressTimer = setInterval(() => {
      if (i < steps.length) {
        this.state.progress = steps[i]
        i++
      }
      if (i >= steps.length) {
        clearInterval(this.progressTimer)
        if (this.state.isAgreed) {
          this.enterApp()
        }
      }
    }, 800)
  }

  enterApp(): void {
    // FWD-REF: P-S10-003 resolve_by=Slice 10 Step 3c — check MMKV_KEY_SHOW_GUIDE
    // If guide not shown → GuidePage else → HomePage
    this.navPathStack.clear()
    this.navPathStack.pushPathByName('HomePage', undefined)
  }

  agreePrivacy(): void {
    this.state.isAgreed = true
    this.state.showPrivacyDialog = false
    // FWD-REF: P-S10-004 resolve_by=Slice 10 Step 3c — persist MMKV_KEY_HAS_AGREE_AGREEMENT = 1
  }

  build() {
    Column() {
      Image($r('app.media.icon_app_logo'))
        .width(80).height(80)
        .borderRadius(16)
        .margin({ top: 200 })

      Text($r('app.string.appName'))
        .fontSize(24).fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1C').margin({ top: 16 })

      Progress({ value: this.state.progress, total: 100, type: ProgressType.Linear })
        .width('60%').height(4)
        .color('#753FF9')
        .backgroundColor('#F5F6FA')
        .margin({ top: 48 })
    }
    .width('100%').height('100%')
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Center)
  }
}
