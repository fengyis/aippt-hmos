import { UserDataModel, getUserData } from '../model/UserDataModel'
@ObservedV2 export class MineViewModel {
  @Trace isLoading: boolean = false
  @Trace cacheSize: string = '0KB'
  @Trace isLoggedIn: boolean = false
  @Trace isVip: boolean = false
  @Trace freeCount: number = 0
  user: UserDataModel = getUserData()
  aboutToAppear(): void { this.isLoggedIn = this.user.isLogin(); this.isVip = this.user.isVip(); this.computeCacheSize() }
  computeCacheSize(): void { /* Compute from cache directory via fileIo */ this.cacheSize = '0KB' }
  clearCache(): void { /* Delete cache files via fileIo */ this.cacheSize = '0KB' }
}
