import { ScanFileBean } from '../model/ScanFileBean'
@ObservedV2 export class FileListViewModel {
  @Trace files: ScanFileBean[] = []
  @Trace isLoading: boolean = false
  @Trace searchKeyword: string = ''
  search(keyword: string): void { this.searchKeyword = keyword; /* FWD-REF: P-S05-002 resolve_by=Slice 5 Step 3c */ }
  scanAll(): void { this.isLoading = true; /* FWD-REF: P-S05-001 resolve_by=Slice 5 Step 3c */ }
}
