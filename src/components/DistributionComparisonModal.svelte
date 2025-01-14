<script>
  import Modal from './Modal.svelte';
  import DistributionComparisonGraph from './explore/DistributionComparisonGraph.svelte';
  import DistributionChart from './explore/DistributionChart.svelte';
  import { store } from '../state/store';
  import routes from '../config/routes';
  import { convertValueToPercentage } from '../utils/probe-utils';

  export let densityMetricType;
  export let topChartData;
  export let bottomChartData;
  export let distViewButtonId;

  let normalized = $store.productDimensions.normalizationType === 'normalized';

  let valueSelector = 'value';
  // Change this value to adjust the minimum tick increment on the chart
  export let tickIncrement = 2;

  // eslint-disable-next-line prefer-destructuring
  let innerHeight = window.innerHeight;
  // eslint-disable-next-line prefer-destructuring
  let innerWidth = window.innerWidth;
  const getTopTick = function (rd, ld) {
    let maxRd = rd ? Math.max(...rd.map((di) => di[valueSelector])) : 0;
    let maxLd = ld ? Math.max(...ld.map((di) => di[valueSelector])) : 0;
    let maxValue = Math.max(maxLd, maxRd);
    let maxValPercent = Math.round(maxValue * 100);
    let topTick =
      (maxValPercent + (tickIncrement - (maxValPercent % tickIncrement))) / 100;
    return topTick;
  };
</script>

<style>
  .charts {
    display: flex;
    flex-direction: column;
  }
  .outer-flex {
    position: relative;
    display: flex;
    min-width: 97vw;
    min-height: 10vh;
    max-height: 75vh;
    margin-left: auto;
    margin-right: auto;
    height: auto;
    flex-direction: row;
    flex: 1;
  }
  .chart-fixed {
    clear: both;
    padding: 0.7%;
    min-width: fit-content;
  }
  .chart-fixed > p {
    font-size: small;
  }
  .percentiles {
    display: flex;
    flex-grow: 1;
    padding: 2%;
    flex-direction: column;
  }

  .dist-modal-details {
    height: 100%;
  }
</style>

<svelte:window bind:innerWidth bind:innerHeight />

{#if topChartData && bottomChartData}
  {@const topChartDensity = normalized
    ? topChartData[densityMetricType]
    : convertValueToPercentage(topChartData[densityMetricType])}
  {@const topChartSampleCount = topChartData.sample_count}
  {@const bottomChartDensity = normalized
    ? bottomChartData[densityMetricType]
    : convertValueToPercentage(bottomChartData[densityMetricType])}
  {@const bottomChartSampleCount = bottomChartData.sample_count}
  {@const topTick = getTopTick(bottomChartDensity, topChartDensity)}
  <Modal>
    <div slot="trigger" let:open>
      <button on:click={open} id={distViewButtonId} hidden
        >Distribution comparison</button
      >
    </div>
    <div slot="title">Distribution comparison - {$store.probe.name}</div>
    <div class="outer-flex">
      <div class="charts">
        <div class="chart-fixed">
          <p>Reference</p>
          {#key innerHeight}
            {#key innerWidth}
              <DistributionComparisonGraph
                {innerHeight}
                {innerWidth}
                density={topChartDensity}
                {topTick}
                {tickIncrement}
              >
                <g slot="glam-body">
                  {#if bottomChartData}
                    <DistributionChart
                      {innerHeight}
                      {innerWidth}
                      density={topChartDensity}
                      {topTick}
                      {tickIncrement}
                      sampleCount={topChartSampleCount}
                      tooltipLocation="bottom"
                    />
                  {/if}
                </g>
              </DistributionComparisonGraph>
            {/key}
          {/key}
        </div>
        <div class="chart-fixed">
          <p>Hovered</p>
          {#key innerHeight}
            {#key innerWidth}
              <DistributionComparisonGraph
                {innerHeight}
                {innerWidth}
                density={bottomChartDensity}
                {topTick}
                {tickIncrement}
              >
                <g slot="glam-body">
                  {#if bottomChartData}
                    <DistributionChart
                      {innerHeight}
                      {innerWidth}
                      density={bottomChartDensity}
                      {topTick}
                      sampleCount={bottomChartSampleCount}
                      tooltipLocation="top"
                    />
                  {/if}
                </g>
              </DistributionComparisonGraph>
            {/key}
          {/key}
        </div>
      </div>
      <div class="percentiles">
        <div class="drawer graphic-body__details">
          <div class="drawer-section-container dist-modal-details">
            <h3 style="align-self: center;">{$store.probe.name}</h3>
            <svelte:component
              this={routes[$store.product].details}
              showLinks={false}
            />
          </div>
        </div>
        <div><hr /></div>
        <slot name="comparisonSummary" />
      </div>
    </div>
  </Modal>
{/if}
