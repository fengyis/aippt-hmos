@ObservedV2
export class HomeViewModel {
  @Trace currentTab: number = 0
  @Trace isExitConfirm: boolean = false

  initUser(): void {
    // FWD-REF: P-S03-001 resolve_by=Slice 3 Step 3c — AuthRepository.initUser()
  }
}
