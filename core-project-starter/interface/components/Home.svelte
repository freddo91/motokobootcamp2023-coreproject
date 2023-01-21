<script>
  import logo from ".././assets/camp_logo.png"
  import ConnectButton from ".././components/shared/ConnectButton.svelte"
  import { principal, ledgerActor, daoActor } from "../stores"
  import { Principal } from "@dfinity/principal"
  import { get } from "svelte/store"

  let periods = [
		{ id: 0, text: `6 months` },
		{ id: 1, text: `1 years` },
		{ id: 2, text: `2 years` },
    { id: 3, text: `3 years` },
		{ id: 4, text: `4 years` },
    { id: 5, text: `5 years` },
		{ id: 6, text: `6 years` },
    { id: 7, text: `7 years` },
		{ id: 8, text: `8 years` }
	];
  let selected;
  let tokens = BigInt(100);

  function handleSubmit() {
		alert(`${selected.id} You staking (${selected.text})"`);
	}

  async function dissolveNeuron() {
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }
    let res = await dao.dissolve_neuron(Principal.fromText("2vxsx-fae"))
    console.log(res)
  }

  async function getNeuron() {
    
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }
    let res = await dao.get_neuron(Principal.fromText("2vxsx-fae"))
    console.log(res)
    if (res.Ok) {
      return res.Ok
    } else {
      throw new Error(res.Err)
    }
    return res;
  }

  async function createNeuron() {
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }
    let dissolve_delay = 24 * 60 * 60 * 1000
    if (selected.id === 0) {
      dissolve_delay = dissolve_delay * 182
    } else {
      dissolve_delay = dissolve_delay * (365 * selected.id)
    }
    let res = await dao.create_neuron(Principal.fromText("2vxsx-fae"), tokens, dissolve_delay)
    console.log(res)
    return res;
  }

  async function getTransactions() {
    if (!principal) {
      return 
    }
    let ledger = get(ledgerActor)
    if (!ledger) {
      return 
    }
    let start = 0;
    let length = 200;
    let res = await ledger.get_transactions({
      length: length,
      start: start
    })
    console.log(res.first_index)
    console.log(res.log_length)
    let total_mint = BigInt(0);
    while (res.log_length > 0) {
      console.log("log length = " + res.log_length)
      for (const x of res.transactions) {
          
          var dateFormat = new Date(Number(BigInt(x.timestamp) / BigInt(1000000)));
          // if (x.kind === 'TRANSFER') {
          //   console.log(x.index)
          //   console.log(x)
          //   console.log(x.kind)
          //   console.log(x.transfer[0].amount)
          //   console.log(x.transfer[0].from.owner.toString())
          //   console.log(x.transfer[0].to.owner.toString())
          //   console.log(dateFormat)
          // }

          if (x.kind === 'MINT' && x.mint[0].to.owner.toString() === get(principal).toText()) {
            console.log(x.index)
            console.log(x)
            console.log(x.kind)
            console.log(x.mint[0].amount)
            console.log(x.mint[0].to.owner.toString())
            console.log(dateFormat)
            total_mint += x.mint[0].amount
          }
      }
      start = start + 200;
      length = length + 200;
      res = await ledger.get_transactions({
        length: length,
        start: start
      })
    }
    tokens = total_mint;
    console.log("token = " + tokens)
    return total_mint;
  }

  function getNeuronStatus(stt) {
    if (stt['Locked'] !== undefined) {
      return "Locked"
    }
    if (stt['Dissolving'] !== undefined) {
      return "Dissolving"
    }
    return "Dissolved"
  }
</script>

<div>
  <header class="App-header">
    <img src={logo} class="App-logo" alt="logo" />
    <p class="slogan">Motoko Bootcamp Dao</p>
    <p class="twitter">← Open me!</p>
    <ConnectButton />

    {#if $principal}
        {#await getNeuron()}
        <h1 class="slogan">Loading...</h1>
        {:then res}
        <p style="color: white">
          Has a neuron!
        </p>

          <form id="form" on:submit|preventDefault={dissolveNeuron} >
            <fieldset>
              <legend>Neuron</legend>
              <table style="border:1px">
                  <tr>
                    <td>id</td><td>{res.id}</td>
                  </tr>
                  <tr>
                    <td>Token amount:</td><td>{res.token_staking}</td>
                  </tr>
                  <tr>
                    <td>Dissolve Delay:</td><td>{res.dissolve_delay}</td>
                  </tr>
                  <tr>
                    <td>Create time:</td><td>{res.createTime}</td>
                  </tr>
                  
                  <tr>
                    <td>Status:</td><td>{getNeuronStatus(res.status)}</td>
                  </tr>
                 
              </table>
            </fieldset>
            {#if getNeuronStatus(res.status) == 'Locked'}
            <div class="btn__wrapper">
              <button type="submit" id="form__btn" class="btn btn2">Dissolve Neuron</button>
            </div>
            {/if}
          </form>
        <!-- <p style="color: white">
          transactions: {getTransactions()}
        </p> -->
        {:catch error}
          {#await getTransactions()}
          <h1 class="slogan">Loading...</h1>
          {:then res1}
          <!-- <button on:click={() => createNeuron()}> Create newron </button> -->
            <form on:submit|preventDefault={createNeuron} style="background-color: yellowgreen;">
              <div>
                <center><a>Create Neuron</a></center>
                <div>
                  <div>
                    <a>Token amount</a>
                    <input type="number" bind:value={tokens}>
                  </div>
                  <div>
                    <a>Period</a>
                    <select bind:value={selected} on:change="{() => tokens = 0}">
                      {#each periods as period}
                        <option value={period}>
                          {period.text}
                        </option>
                      {/each}
                    </select>
                  </div>
                  <!-- <div class="card-cvv">
                    <a>CVV:</a>
                    <input id="cardcvv" autocomplete="***" maxlength="4">
                  </div> -->
                  <button disabled={tokens === 0} type=submit>
                    <span>Create newron</span>
                  </button>
                </div>
              </div>
            </form>
          {:catch error}
            <p style="color: red">{error.message}</p>
          {/await}
          <p style="color: red">{error.message}</p>
        {/await}
    {/if}
  </header>
</div>

<style>
html,
body {
  padding: 0;
  margin: 0;
  height: 100%;
}
input {
  height: 15px;
  border: 0;
  outline: 1px solid;
  border-radius: 3px;
}

body {
  height: 100vh;
  width: 100vw;
  background-color:aliceblue;
  display: grid;
  place-content: center;
  gap: 0.5em;

  text-align: center;
  line-height: 1.42;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen",
    "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue",
    sans-serif;
}

form {
  background-color:white;
  display: flex;
  flex-direction: column;
  gap: 1em;
  border: 2px dotted;
  padding: 20px 10px;
}

input:invalid {
  background-color: rgb(255, 231, 231);
}

input:valid {
  background-color: rgb(224, 255, 218);
}

.group {
  display: flex;
  /* outline: 1px solid; */
  align-items: center;
  justify-content: space-between;
}
.group label {
  width: 50px;
}

fieldset {
  display: flex;
  flex-direction: column;
  border: 1px dotted;
  gap: 1em;
}

legend {
  font-weight: 600;
}

input[type="submit"] {
  height: auto;
  background-color: transparent;
  padding: 5px;
}

input[type="submit"]:hover {
  background-color: rgb(244, 244, 244);
}

</style>