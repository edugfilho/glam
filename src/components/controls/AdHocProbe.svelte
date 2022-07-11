<script>
  import GlamErrorShapes from '../errors/GlamErrorShapes.svelte';
  import Spinner from '../../components/LineSegSpinner.svelte';
  import { dataset, store } from '../../state/store';
  import { getAdHocStatus } from '../../state/api';

  export let reason =
    'This probe needs to be built first. Please follow the instructions below to do so';
  export let moreInformation =
    'Please make sure Channel, OS and Process are correct and click the button below to build this probe';

  let spin = false;

  function callme() {
    //This promise will resolve when the network call succeeds

    var networkPromise = getAdHocStatus(
      $store.probe.name,
      $store.productDimensions.channel,
      $store.productDimensions.process,
      $store.productDimensions.os
    );

    //This promise will resolve when 2 seconds have passed
    var timeOutPromise = new Promise(function (resolve, reject) {
      // 2 Second delay
      setTimeout(resolve, 2000, 'Timeout Done');
    });

    Promise.all([networkPromise, timeOutPromise]).then(function (values) {
      //Repeat
      let result = values[0]
      if (result['status'] === "SUCCESS") {
        store.setField('ad_hoc_loaded', true);
        location.reload()
      } else if (result['status'] === "FAILED") {
        console.log("FAIL")
      } else {
        callme()
      }
    });
  }
</script>

<style>
  .data-error-msg {
    /* background-color: var(--cool-gray-050); */
    border-radius: var(--space-1h);

    padding: var(--space-4x);
    display: grid;
    align-items: center;
    justify-items: center;
    align-content: center;
    height: 300px;
    --error-msg-width: 400px;
    --error-msg-color: var(--cool-gray-500);
    margin-top: var(--space-16x);
    margin-bottom: var(--space-2x);
  }

  .data-error-msg__bg {
    background: radial-gradient(var(--cool-gray-100), var(--cool-gray-100));
    /* box-shadow: inset 0px 0px 10px rgba(0,0,0,.1); */
    width: 200px;
    height: 200px;
    padding: var(--space-4x);
    border-radius: 50%;
    margin-top: var(--space-2x);
  }

  .data-error-msg__reason {
    padding-top: var(--space-4x);
    width: var(--error-msg-width);
    font-size: var(--text-05);
    font-weight: bold;
    margin-bottom: var(--space-2x);
    color: var(--error-msg-color);
    text-align: center;
  }

  .data-error-msg__more-information {
    width: var(--error-msg-width);
    color: var(--error-msg-color);
    line-height: 1.5;
    margin-bottom: var(--space-2x);
    font-style: italic;
    color: var(--error-msg-color);
  }

  .data-error-msg__call-to-action {
    width: var(--error-msg-width);
    color: var(--error-msg-color);
    line-height: 1.5;
  }
</style>
{#if $store.ad_hoc_loaded}
  {#await $dataset}
    <div class="graphic-body__content">
      <Spinner size={48} color={'var(--cool-gray-400)'} />
    </div>
  {/await}
{:else}
  <div class="data-error-msg">
    <div class="data-error-msg__reason">{reason}</div>
    <div class="data-error-msg__bg">
      <GlamErrorShapes />
    </div>

    {#if moreInformation}
      <div
        class="data-error-msg__more-information"
        style="font-size: small; padding-top: 5%;">
        {moreInformation}
      </div>
    {/if}
    <div class="data-error-msg__call-to-action">
      <div
        style="display: grid; align-content: center; align-items:center ; padding-top: 5%;">
        {#if spin}
          <div class="graphic-body__content">
            <Spinner size={48} color={'var(--cool-gray-400)'} />
          </div>
        {:else}
          <button
            class="gp-button gp-button--low gp-button--standard gp-button-text--standard"
            style="text-align: center;"
            on:click={() => {
              spin = true;
              callme();
            }}>BUILD IT NOW</button>
        {/if}
      </div>
      If you think this is a bug, report this on the
      <a href="https://mozilla.slack.com/archives/CB1EQ437S">#glam</a>
      channel on Mozilla's Slack instance or in the
      <a href="https://github.com/mozilla/glam/issues/new"
        >GLAM github repository</a
      >.
    </div>
  </div>
{/if}
