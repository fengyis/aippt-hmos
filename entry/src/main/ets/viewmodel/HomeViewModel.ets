import { AuthRepository } from '../service/AuthRepository'

@ObservedV2
export class HomeViewModel {
  @Trace currentTab: number = 0
  @Trace isExitConfirm: boolean = false

  private authRepo: AuthRepository = new AuthRepository()

  async initUser(): Promise<void> {
    await this.authRepo.initUser()
  }
}
