@ObservedV2
export class ProductBean {
  @Trace productId: string = ''
  @Trace name: string = ''
  @Trace showNowPrice: string = ''
  @Trace showOriginalPrice: string = ''
  @Trace showBtn: string = '立即开通'
  @Trace showDesc: string = ''
  @Trace period: string = ''
  @Trace periodUnit: string = ''
  @Trace benefits: string[] = []
  @Trace selected: boolean = false
  @Trace payMethod: number = 1
  @Trace paymentChannel: number = 1
  @Trace isCt: boolean = false
  extJson: string = ''

  static fromJson(json: Record<string, Object>): ProductBean {
    const p = new ProductBean()
    p.productId = (json['productId'] as string) ?? ''
    p.name = (json['name'] as string) ?? ''
    p.showNowPrice = (json['showNowPrice'] as string) ?? ''
    p.showOriginalPrice = (json['showOriginalPrice'] as string) ?? ''
    p.showDesc = (json['showDesc'] as string) ?? ''
    p.period = (json['period'] as string) ?? ''
    p.periodUnit = (json['periodUnit'] as string) ?? ''
    return p
  }
}
