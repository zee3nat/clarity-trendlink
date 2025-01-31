import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures users can create predictions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-market", "create-prediction", 
        ["Test prediction", types.uint(100), types.uint(144)], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u0");
  },
});

Clarinet.test({
  name: "Ensures users can make predictions with sufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-market", "create-prediction",
        ["Test prediction", types.uint(100), types.uint(144)],
        wallet_1.address
      ),
      Tx.contractCall("trend-market", "make-prediction",
        [types.uint(0), types.bool(true), types.uint(100)],
        wallet_2.address
      )
    ]);

    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
