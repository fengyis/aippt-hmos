import { UserDataModel, getUserData } from '../model/UserDataModel'
import { AuthRepository } from '../service/AuthRepository'

@ObservedV2
export class AuthViewModel {
  @Trace phoneNumber: string = ''
  @Trace smsCode: string = ''
  @Trace isLoggingIn: boolean = false
  @Trace smsCountdown: number = 0
  @Trace isAgreementChecked: boolean = false
  @Trace loginSuccess: boolean = false
  @Trace errorMessage: string = ''
  @Trace loginSuccess: boolean = false
  @Trace smsCountdown: number = 0
  @Trace isAgreementChecked: boolean = false

  private user: UserDataModel = getUserData()
  private repository: AuthRepository = new AuthRepository()

  validatePhone(phone: string): boolean {
    if (phone.length === 0) { this.errorMessage = '手机号不能为空'; return false }
    if (phone.length < 11) { this.errorMessage = '请填写完整的手机号'; return false }
    if (!/^1[3-9]\d{9}$/.test(phone)) { this.errorMessage = '手机号码错误'; return false }
    return true
  }

  checkPrivacy(): boolean {
    if (!this.isAgreementChecked) { this.errorMessage = '请先同意服务条款和隐私政策'; return false }
    return true
  }

  async sendSms(phone: string): Promise<void> {
    if (!this.validatePhone(phone)) return
    this.smsCountdown = 60
    const resp = await this.repository.sendSms(phone)
    if (!resp.isSuccess()) { this.errorMessage = resp.msg || '发送验证码失败'; this.smsCountdown = 0 }
  }

  async login(phone: string, code: string): Promise<boolean> {
    if (!this.checkPrivacy()) return false
    if (!phone || !code) { this.errorMessage = '请输入手机号和验证码'; return false }
    this.isLoggingIn = true
    try {
      const resp = await this.repository.login(phone, code)
      if (resp.isSuccess()) { this.loginSuccess = true; return true }
      this.errorMessage = resp.msg || '登录失败'
      return false
    } finally {
      this.isLoggingIn = false
    }
  }

  async logout(): Promise<void> {
    await this.repository.logout()
    this.user.token = ''
  }

  async initUser(): Promise<void> {
    await this.repository.initUser()
  }
}
