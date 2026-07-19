@ObservedV2 export class SplashViewModel {
  @Trace progress: number = 0
  @Trace isAgreed: boolean = false
  @Trace isLoaded: boolean = false
  @Trace showPrivacyDialog: boolean = true

  agreePrivacy(): void { this.isAgreed = true; this.showPrivacyDialog = false }
  startProgress(): void { this.isLoaded = true }
  checkGuideFlag(): boolean { return false /* PersistenceV2 read */ }
}
