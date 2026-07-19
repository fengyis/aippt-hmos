@ObservedV2 export class GuideViewModel {
  @Trace step: number = 0
  @Trace totalSteps: number = 6
  @Trace countdown: number = 5
  @Trace autoPlay: boolean = true

  goNext(): void { if (this.step < this.totalSteps - 1) this.step++ }
  goBack(): void { if (this.step > 0) this.step-- }
  isComplete(): boolean { return this.step >= this.totalSteps - 1 }
  markGuideShown(): void { /* PersistenceV2 set show_guide = true */ }
  enterHome(): void { this.markGuideShown() }
}
