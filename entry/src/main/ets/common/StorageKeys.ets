import { PersistenceV2 } from '@kit.ArkUI'
import { UserDataModel } from '../model/UserDataModel'
import { VipFloatBean } from '../model/VipFloatBean'

export class StorageKeys {
  static readonly USER_DATA = 'user_data'
  static readonly PRIVACY_AGREED = 'privacy_agreed'
  static readonly SHOW_GUIDE = 'show_guide'
  static readonly USER_TIP_AGREED = 'user_tip_agreed'
}

export class AppConfig {
  showServiceCenter: number = 1
}
