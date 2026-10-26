import { useState } from 'react';
import { BrowserProvider, Contract, formatUnits, isAddress, parseUnits } from 'ethers';
import { Bug, CheckCircle2, CircleAlert, Code2, Play, ShieldAlert, Wallet } from 'lucide-react';

const SCENARIO_ABI = [
  'function runScenario(uint256 attackerDeposit,uint256 donation,uint256 victimDeposit) returns (uint256 referenceVictimShares,uint256 vulnerableVictimShares)',
  'event ScenarioCompleted(address indexed caller,address token,address referenceVault,address vulnerableVault,uint256 attackerDeposit,uint256 donation,uint256 victimDeposit,uint256 referenceVictimShares,uint256 vulnerableVictimShares,uint256 referenceAttackerShares,uint256 vulnerableAttackerShares,uint256 referenceTotalAssets,uint256 vulnerableTotalAssets)',
];

function validAmount(input, allowZero = false) {
  try {
    const amount = parseUnits(input, 18);
    return input !== '' && (allowZero ? amount >= 0n : amount > 0n);
  } catch {
    return false;
  }
}

const formatShares = (amount) => Number(formatUnits(amount, 18)).toLocaleString(undefined, { maximumFractionDigits: 8 });
const errorMessage = (error) => error?.shortMessage || error?.reason || error?.message || 'Scenario transaction failed.';

function comparison(reference, vulnerable) {
  return reference > 0n ? Number((reference - vulnerable) * 10000n / reference) / 100 : null;
}

export default function ScenarioLab({ config, wallet, connect, navigate }) {
  const [attacker, setAttacker] = useState('1');
  const [donation, setDonation] = useState('1');
  const [victim, setVictim] = useState('5');
  const [result, setResult] = useState(null);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState('');
  const valid = validAmount(attacker) && validAmount(donation, true) && validAmount(victim);
  const scenarioConfigured = isAddress(config.inflationScenario);

  function update(setter, value) {
    setter(value);
    setResult(null);
    setError('');
  }

  function compareLocally() {
    if (!valid) return;
    const a = parseUnits(attacker, 18);
    const d = parseUnits(donation, 18);
    const v = parseUnits(victim, 18);
    const reference = v * a / (a + d);
    const vulnerable = v * a / (a + d + v);
    setResult({ source: 'model', reference, vulnerable, reduction: comparison(reference, vulnerable) });
    setError('');
  }

  async function runOnChain() {
    if (!valid || !scenarioConfigured || !wallet || !window.ethereum) return;
    setRunning(true);
    setError('');
    setResult(null);
    try {
      const provider = new BrowserProvider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 31337n) {
        throw new Error('Switch your wallet to Anvil (chain ID 31337).');
      }
      const signer = await provider.getSigner();
      if ((await signer.getAddress()).toLowerCase() !== wallet.toLowerCase()) {
        throw new Error('Your wallet account changed. Reconnect and retry.');
      }
      if (await provider.getCode(config.inflationScenario) === '0x') {
        throw new Error('Scenario contract not found. Deploy it on this Anvil chain and update its address in Environment.');
      }
      const scenario = new Contract(config.inflationScenario, SCENARIO_ABI, signer);
      const tx = await scenario.runScenario(
        parseUnits(attacker, 18), parseUnits(donation, 18), parseUnits(victim, 18)
      );
      const receipt = await tx.wait();
      if (!receipt || receipt.status !== 1) throw new Error('Scenario transaction reverted.');
      let completed;
      for (const log of receipt.logs) {
        if (log.address.toLowerCase() !== config.inflationScenario.toLowerCase()) continue;
        const parsed = scenario.interface.parseLog(log);
        if (parsed?.name === 'ScenarioCompleted') { completed = parsed.args; break; }
      }
      if (!completed) throw new Error('Transaction confirmed, but ScenarioCompleted was not found in its receipt.');
      const reference = completed.referenceVictimShares;
      const vulnerable = completed.vulnerableVictimShares;
      setResult({
        source: 'chain', reference, vulnerable,
        reduction: comparison(reference, vulnerable),
        referenceAssets: completed.referenceTotalAssets,
        vulnerableAssets: completed.vulnerableTotalAssets,
        hash: receipt.hash, block: receipt.blockNumber,
      });
    } catch (caught) {
      setError(errorMessage(caught));
    } finally {
      setRunning(false);
    }
  }

  return <>
    <div className="lab-hero"><span className="lab-icon"><Bug size={25}/></span><div><span className="eyebrow">CONTROLLED TEST ENVIRONMENT</span><h2>Test the failure. Understand the fix.</h2><p>Compare the same first deposit, donation, and victim deposit against the two Solidity implementations.</p></div></div>
    <div className="two-col"><div className="panel vault-stat reference"><span className="vault-label"><CheckCircle2 size={16}/> REFERENCE IMPLEMENTATION</span><h2>MockERC4626</h2><p>Calculates victim shares using the vault state before the deposit.</p></div><div className="panel vault-stat vulnerable"><span className="vault-label"><ShieldAlert size={16}/> VULNERABLE IMPLEMENTATION</span><h2>VulnerableVault</h2><p>Calculates victim shares after the victim's assets enter the vault.</p></div></div>
    <div className="panel"><div className="panel-header"><div><h2>Inflation attack comparison</h2><p>Preview the integer arithmetic, or execute the isolated scenario on local Anvil.</p></div><span className={`badge ${result?.source === 'chain' ? 'good' : 'neutral'}`}>{result?.source === 'chain' ? 'ON-CHAIN RESULT' : 'LOCAL LAB'}</span></div>
      <div className="form-grid three">{[
        ['Attacker’s first deposit', attacker, setAttacker],
        ['Direct donation', donation, setDonation],
        ['Victim’s deposit', victim, setVictim],
      ].map(([label, value, setter]) => <label className="field" key={label}><span>{label} (mUSD)</span><input type="text" inputMode="decimal" value={value} disabled={running} onChange={event => update(setter, event.target.value)}/></label>)}</div>
      <div className="button-row"><button className="secondary-button" disabled={!valid || running} onClick={compareLocally}><Play size={15}/> Compare locally</button><button className="primary-button" disabled={!valid || running || !scenarioConfigured || !wallet} onClick={runOnChain}><Wallet size={15}/>{running ? 'Waiting for confirmation…' : 'Run on Anvil'}</button></div>
      {!valid && <p className="field-error">Enter positive deposits and a nonnegative donation, with at most 18 decimal places.</p>}
      {!scenarioConfigured && <p className="helper">To run on chain, deploy the scenario contract and add its address in <button className="text-button" onClick={() => navigate('Environment')}>Environment</button>.</p>}
      {scenarioConfigured && !wallet && <p className="helper">Connect a funded Anvil wallet to run the on-chain scenario. <button className="text-button" onClick={connect}>Connect wallet</button></p>}
      {running && <p className="helper">Confirm the transaction in your wallet and wait for its receipt.</p>}
      {error && <div className="inline-feedback" role="alert">{error}</div>}
      {result && <><div className="two-col result-grid"><div className="result-card reference"><small>REFERENCE · VICTIM SHARES</small><strong>{formatShares(result.reference)}</strong><p>{result.source === 'chain' ? `Total assets: ${formatShares(result.referenceAssets)} mUSD` : 'Calculated before the victim’s assets enter.'}</p></div><div className="result-card vulnerable"><small>VULNERABLE · VICTIM SHARES</small><strong>{formatShares(result.vulnerable)}</strong><p>{result.source === 'chain' ? `Total assets: ${formatShares(result.vulnerableAssets)} mUSD` : 'Calculated after the victim’s assets enter.'}</p></div></div><div className="result-callout"><CircleAlert size={20}/><span><strong>{result.reduction === null ? 'No reference shares' : `${result.reduction.toFixed(2)}% fewer shares`}</strong> for the victim in the vulnerable implementation. {result.source === 'chain' ? `Confirmed on Anvil in block #${result.block}.` : 'This is a local calculation with Solidity-style integer rounding.'}</span></div>{result.hash && <p className="helper">Local transaction hash: <code className="scenario-hash">{result.hash}</code></p>}</>}
    </div>
    <div className="info-strip"><span className="info-icon"><Code2 size={19}/></span><div><strong>Independent execution on every run</strong><p>The scenario contract creates fresh mock token and vault instances, then emits their allocations. It spends only local Anvil gas. The local comparison does not send a transaction. Run <code>forge test --match-contract InflationAttackComparisonTest -vv</code> for the Foundry differential test.</p></div></div>
  </>;
}
