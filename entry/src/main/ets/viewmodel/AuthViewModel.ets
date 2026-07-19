import { UserDataModel, getUserData } from '../model/UserDataModel'

@ObservedV2
export class AuthViewModel {
  @Trace phoneNumber: string = ''
  @Trace smsCode: string = ''
  @Trace isLoggingIn: boolean = false
  @Trace smsCountdown: number = 0
  @Trace isAgreementChecked: boolean = false
  @Trace loginSuccess: boolean = false
  @Trace errorMessage: string = ''

  private user: UserDataModel = getUserData()

  validatePhone(phone: string): boolean {
    return phone.length === 11 && /^1[3-9]\d{9}$/.test(phone)
  }

  async login(phone: string, code: string): Promise<void> {
    this.isLoggingIn = true
    try {
      // FWD-REF: P-S01-001 resolve_by=Slice 1 Step 3c — AuthRepository.login(phone, code)
      this.loginSuccess = true
    } finally {
      this.isLoggingIn = false
    }
  }

  async logout(): Promise<void> {
    // FWD-REF: P-S01-004 resolve_by=Slice 1 Step 3c — AuthRepository.logout()
    this.user.token = ''
  }
}
