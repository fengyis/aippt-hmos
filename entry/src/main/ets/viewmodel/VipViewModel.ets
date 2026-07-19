import { ProductBean } from '../model/ProductBean'
@ObservedV2 export class VipViewModel {
  @Trace products: ProductBean[] = []
  @Trace selectedIndex: number = 0
  @Trace paymentChannel: number = 1
  @Trace agreementChecked: boolean = false
  @Trace isLoading: boolean = false
  @Trace paySuccess: boolean = false
  fetchProductList(): void { /* FWD-REF: P-S02-001 resolve_by=Slice 2 Step 3c */ }
  createOrder(): void { /* PLACEHOLDER: P-S2-1 P-S2-2 P-S2-3 resolve_by=Slice 2 Step 3c */ }
}
