import { HttpClient } from '../network/HttpClient'
import { BaseResponse } from '../model/BaseResponse'
import { UserDataModel, getUserData } from '../model/UserDataModel'

export class AuthRepository {
  private client = HttpClient.getInstance()
  private user = getUserData()

  async login(phone: string, code: string): Promise<BaseResponse<UserDataModel>> {
    const resp = await this.client.post<UserDataModel>('/user/login', { phone: phone, smsCode: code })
    if (resp.data) {
      this.user.token = resp.data.token ?? ''
      this.user.userId = resp.data.userId ?? ''
      this.user.vipLevel = resp.data.vipLevel ?? -10
    }
    return resp
  }

  async sendSms(phone: string): Promise<BaseResponse<null>> {
    return this.client.post<null>('/user/sms', { phone: phone })
  }

  async logout(): Promise<void> {
    try { await this.client.post('/user/logout') } catch (_) {}
    this.user.token = ''
  }

  async initUser(): Promise<void> {
    try { await this.client.post('/user/init') } catch (_) {}
  }
}
