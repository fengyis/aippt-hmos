@ObservedV2 export class SplashViewModel {
  @Trace progress: number = 0
  @Trace isAgreed: boolean = false
  @Trace isLoaded: boolean = false
  agreePrivacy(): void { this.isAgreed = true }
}
