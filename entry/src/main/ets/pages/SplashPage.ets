import { SplashViewModel } from '../viewmodel/SplashViewModel'

@ObservedV2
class SplashState {
  @Trace progress: number = 0
  @Trace showPrivacyDialog: boolean = true
  @Trace isLoading: boolean = true
  @Trace isAgreed: boolean = false
  @Trace hotLaunch: boolean = false
}

@Entry
@ComponentV2
struct SplashPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: SplashState = new SplashState()
  @Local splashVM: SplashViewModel = new SplashViewModel()
  private progressTimer: number = -1

  aboutToAppear(): void {
    this.state.showPrivacyDialog = !this.splashVM.isAgreed
    this.startProgressAnimation()
  }

  startProgressAnimation(): void {
    const steps = [0, 50, 80, 100]
    let i = 0
    this.progressTimer = setInterval(() => {
      if (i < steps.length) { this.state.progress = steps[i]; i++ }
      if (i >= steps.length) {
        clearInterval(this.progressTimer)
        if (this.state.isAgreed) { this.enterApp() }
      }
    }, 800)
  }

  enterApp(): void {
    const showGuide = !this.splashVM.checkGuideFlag()
    this.navPathStack.clear()
    this.navPathStack.pushPathByName(showGuide ? 'GuidePage' : 'HomePage', undefined)
  }

  agreePrivacy(): void {
    this.state.isAgreed = true
    this.state.showPrivacyDialog = false
    this.splashVM.agreePrivacy()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
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

      if (this.state.showPrivacyDialog) {
        Column() {
          Text('隐私协议').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#172939')
          Text('在使用本应用前，请您阅读并同意《服务条款》和《隐私政策》')
            .fontSize(14).fontColor('#868686')
            .textAlign(TextAlign.Center)
            .margin({ top: 12, bottom: 24 })
          Row() {
            Button('不同意')
              .fontSize(14).fontColor('#1C1C1C').backgroundColor('#E6E3FF')
              .borderRadius(20).layoutWeight(1)
              .onClick(() => { /* exit app */ })
            Button('同意').fontSize(14).fontColor(Color.White).backgroundColor('#5B3CFF')
              .borderRadius(20).layoutWeight(1).margin({ left: 12 })
              .onClick(() => this.agreePrivacy())
          }.width('100%')
        }
        .padding(24).borderRadius(12).backgroundColor(Color.White)
        .margin({ left: 24, right: 24, bottom: 40 })
      }
    }
    .width('100%').height('100%')
  }
}
