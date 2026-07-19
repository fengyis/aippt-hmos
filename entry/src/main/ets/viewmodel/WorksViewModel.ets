import { PPTCreateTable, PPTCollectTable } from '../model/DbModels'
@ObservedV2 export class WorksViewModel {
  @Trace tabType: number = 1
  @Trace isDeleteMode: boolean = false
  @Trace works: PPTCreateTable[] = []
  @Trace collects: PPTCollectTable[] = []
  @Trace isLoading: boolean = false
  @Trace isEmpty: boolean = true
  findAll(): void { this.isLoading = true; /* FWD-REF: P-S06-001 resolve_by=Slice 6 Step 3c — PptDbViewModel.findAllPPT() */ }
  queryCollects(): void { /* FWD-REF: P-S06-002 resolve_by=Slice 6 Step 3c */ }
  deleteSelected(items: PPTCreateTable[]): void { /* FWD-REF: P-S06-003 resolve_by=Slice 6 Step 3c */ }
}
