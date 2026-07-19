import { AppStorageV2 } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { AppTitleBar } from '../components/AppTitleBar'
import { AuthViewModel } from '../viewmodel/AuthViewModel'

@ObservedV2
class LoginState {
  @Trace phoneNumber: string = ''
  @Trace smsCode: string = ''
  @Trace isAgreementChecked: boolean = false
  @Trace smsCountdown: number = 0
  @Trace isSmsSending: boolean = false
  @Trace isLoggingIn: boolean = false
  @Trace loginSuccess: boolean = false
  @Trace errorMessage: string = ''
}

@Entry
@ComponentV2
struct LoginPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: LoginState = new LoginState()
  @Local auth: AuthViewModel = new AuthViewModel()
  private phoneController: TextInputController = new TextInputController()
  private codeController: TextInputController = new TextInputController()
  private countdownTimer: number = -1

  aboutToAppear(): void {
    this.state = new LoginState()
  }

  validatePhone(phone: string): boolean {
    if (phone.length === 0) {
      promptAction.showToast({ message: '手机号不能为空' })
      return false
    }
    if (phone.length < 11) {
      promptAction.showToast({ message: '请填写完整的手机号' })
      return false
    }
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      promptAction.showToast({ message: '手机号码错误' })
      return false
    }
    return true
  }

  checkPrivacy(): boolean {
    if (!this.state.isAgreementChecked) {
      promptAction.showToast({ message: '请先同意服务条款和隐私政策' })
      return false
    }
    return true
  }

  async onGetCode(): Promise<void> {
    if (!this.validatePhone(this.state.phoneNumber)) { return }
    this.state.isSmsSending = true
    this.state.smsCountdown = 60
    this.startCountdown()
    await this.auth.sendSms(this.state.phoneNumber)
  }

  startCountdown(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
    this.countdownTimer = setInterval(() => {
      if (this.state.smsCountdown > 0) {
        this.state.smsCountdown--
      } else {
        this.state.isSmsSending = false
        clearInterval(this.countdownTimer)
        this.countdownTimer = -1
      }
    }, 1000)
  }

  async onLogin(): Promise<void> {
    if (!this.checkPrivacy()) { return }
    if (this.state.phoneNumber.length === 0 || this.state.smsCode.length === 0) {
      promptAction.showToast({ message: '请输入手机号和验证码' }); return
    }
    this.state.isLoggingIn = true
    try {
      const ok = await this.auth.login(this.state.phoneNumber, this.state.smsCode)
      if (ok) { this.state.loginSuccess = true; this.navPathStack.pop() }
      else { promptAction.showToast({ message: this.auth.errorMessage || '登录失败' }) }
    } catch (_) {
      promptAction.showToast({ message: '登录失败' })
    } finally {
      this.state.isLoggingIn = false
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: $r('app.string.login'), showBack: false })

        Column() {
          Text($r('app.string.login_title'))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1C')
          Text($r('app.string.login_subtitle'))
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 40 })

        Row() {
          TextInput({ placeholder: $r('app.string.phone_hint'), text: this.state.phoneNumber, controller: this.phoneController })
            .type(InputType.Number)
            .maxLength(11)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.state.phoneNumber = value
            })
          if (this.state.phoneNumber.length > 0) {
            SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
              .fontSize(18)
              .fontColor(['#999999'])
              .margin({ left: 8 })
              .onClick(() => {
                this.state.phoneNumber = ''
              })
          }
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F7F7F7')
        .borderRadius(24)
        .padding({ left: 16, right: 12 })
        .margin({ top: 32, left: 24, right: 24 })

        Row() {
          TextInput({ placeholder: $r('app.string.code_hint'), text: this.state.smsCode, controller: this.codeController })
            .type(InputType.Number)
            .maxLength(6)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.state.smsCode = value
            })
          Button(this.state.isSmsSending ? `${this.state.smsCountdown}s` : $r('app.string.get_code'))
            .fontSize(13)
            .fontColor(this.state.isSmsSending ? '#999999' : '#5B3CFF')
            .backgroundColor(Color.Transparent)
            .enabled(!this.state.isSmsSending)
            .onClick(() => this.onGetCode())
        }
        .width('100%')
        .height(48)
        .backgroundColor('#F7F7F7')
        .borderRadius(24)
        .padding({ left: 16, right: 12 })
        .margin({ top: 16, left: 24, right: 24 })

        Row() {
          Checkbox()
            .select(this.state.isAgreementChecked)
            .selectedColor('#5B3CFF')
            .onChange((value: boolean) => {
              this.state.isAgreementChecked = value
            })
          Text($r('app.string.privacy_agreement_text'))
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(2)
        }
        .margin({ top: 16, left: 24, right: 24 })

        Button($r('app.string.login'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
          .height(48)
          .borderRadius(24)
          .backgroundColor('#5B3CFF')
          .loading(this.state.isLoggingIn)
          .margin({ top: 24, left: 24, right: 24 })
          .onClick(() => this.onLogin())

        Row() {
          Divider().layoutWeight(1)
          Text($r('app.string.quick_login'))
            .fontSize(12)
            .fontColor('#B0B1B3')
            .margin({ left: 12, right: 12 })
          Divider().layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 32, left: 40, right: 40 })

        Row() {
          Column() {
            Image($r('app.media.icon_wechat_login'))
              .width(48).height(48)
            Text('微信').fontSize(11).fontColor('#666666').margin({ top: 4 })
          }
          .onClick(() => { /* PLACEHOLDER: WeChat SDK login */ })
          .margin({ right: 40 })

          Column() {
            Image($r('app.media.icon_ali_login'))
              .width(48).height(48)
            Text('支付宝').fontSize(11).fontColor('#666666').margin({ top: 4 })
          }
          .onClick(() => { /* PLACEHOLDER: Alipay SDK login */ })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: 28 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .title('')
    .hideTitleBar(true)
  }
}
