import { UserDataModel, getUserData } from '../model/UserDataModel'
@ObservedV2 export class MineViewModel {
  @Trace isLoading: boolean = false
  @Trace cacheSize: string = '0KB'
  @Trace isLoggedIn: boolean = false
  @Trace isVip: boolean = false
  @Trace freeCount: number = 0
  user: UserDataModel = getUserData()
  aboutToAppear(): void { this.isLoggedIn = this.user.isLogin(); this.isVip = this.user.isVip() }
  computeCacheSize(): void { /* FWD-REF: P-S07-001 resolve_by=Slice 7 Step 3c */ }
  clearCache(): void { /* FWD-REF: P-S07-002 resolve_by=Slice 7 Step 3c */ }
}
