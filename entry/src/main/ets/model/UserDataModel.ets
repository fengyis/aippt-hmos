import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI'

@ObservedV2
export class UserDataModel {
  @Trace token: string = ''
  @Trace userId: string = ''
  @Trace nickname: string = ''
  @Trace avatar: string = ''
  @Trace vipLevel: number = -10
  @Trace vipDayRemain: string = ''
  @Trace fromChannel: string = ''
  @Trace phone: string = ''
  @Trace isBinding: boolean = false
  @Trace interceptAuth: number = 0
  @Trace freeCount: number = 0

  isLogin(): boolean {
    return this.token.length > 0
  }

  isVip(): boolean {
    return this.vipLevel >= 2
  }

  static fromJson(json: Record<string, Object>): UserDataModel {
    const m = new UserDataModel()
    m.token = (json['token'] as string) ?? ''
    m.userId = (json['userId'] as string) ?? ''
    m.nickname = (json['nickname'] as string) ?? ''
    m.avatar = (json['avatar'] as string) ?? ''
    m.vipLevel = (json['vipLevel'] as number) ?? -10
    m.vipDayRemain = (json['vipDayRemain'] as string) ?? ''
    m.fromChannel = (json['fromChannel'] as string) ?? ''
    m.phone = (json['phone'] as string) ?? ''
    return m
  }
}

export const USER_DATA_KEY = 'user_data'
export function getUserData(): UserDataModel {
  return AppStorageV2.connect(UserDataModel, USER_DATA_KEY, () => new UserDataModel())!
}
