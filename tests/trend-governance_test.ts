import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures users can only vote once per resolution",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-governance", "vote-on-resolution",
        [types.uint(1), types.bool(true)],
        wallet_1.address
      ),
      Tx.contractCall("trend-governance", "vote-on-resolution", 
        [types.uint(1), types.bool(false)],
        wallet_1.address
      )
    ]);

    assertEquals(block.receipts[0].result.expectOk(), true);
    assertEquals(block.receipts[1].result.expectErr(), 403);
  },
});
