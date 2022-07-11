<script>
  import { fly } from 'svelte/transition';
  import DataError from '../../components/errors/DataError.svelte';
  import AdHocProbe from '../../components/controls/AdHocProbe.svelte';
  import ProbeTitle from '../../components/regions/ProbeTitle.svelte';
  import Spinner from '../../components/LineSegSpinner.svelte';
  import { dataset, store } from '../../state/store';
  import { isSelectedProcessValid } from '../../utils/probe-utils';

  // TODO: this flag must probably come from the backend or be derived by a response:
  // e.g. in case a probe doesn't exist in probe dictionary, this should be false.
  store.setField('request_ad_hoc', true);
</script>

{#if $store.probe.loaded}
  {#await $dataset}
    <div class="graphic-body__content">
      <Spinner size={48} color={'var(--cool-gray-400)'} />
    </div>
  {:then data}
    {#if $store.product === 'firefox' && $store.probe.active === false}
      <div class="graphic-body__content">
        <ProbeTitle />
        <div in:fly={{ duration: 400, y: 10 }}>
          <DataError
            reason={'This probe is inactive and is no longer collecting data.'} />
        </div>
      </div>
    {:else if $store.product === 'firefox' && !isSelectedProcessValid($store.probe.seen_in_processes, $store.productDimensions.process)}
      <div class="graphic-body__content">
        <ProbeTitle />
        <div in:fly={{ duration: 400, y: 10 }}>
          <DataError
            reason={`This probe does not record in the ${$store.productDimensions.process} process.`} />
        </div>
      </div>
    {:else}
      <slot {data} probeType={data.viewType} />
    {/if}
  {:catch err}
    {#if $store.request_ad_hoc}
      <div class="graphic-body__content">
        <ProbeTitle />
        <div in:fly={{ duration: 400, y: 10 }}>
          <AdHocProbe />
        </div>
      </div>
    {:else}
      <div class="graphic-body__content">
        <ProbeTitle />
        <div in:fly={{ duration: 400, y: 10 }}>
          <DataError
            reason={err.message}
            moreInformation={err.moreInformation} />
        </div>
      </div>
    {/if}
  {/await}
{/if}
