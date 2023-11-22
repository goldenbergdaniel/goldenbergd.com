<script lang="ts">
  import Title from "$lib/Title.svelte";
</script>

<div>
  <div class="title">
    <Title text="goldenbergd.com"/>
  </div>
  <p>My name is Daniel Goldenberg. This is my website.</p>
</div>

<style lang="scss">
  .title
  {
    text-align: center;
    color: rgb(230, 230, 230);
    font-size: 16px;
  }

  p
  {
    text-align: center;
    margin-top: 30px;
    color: rgb(180, 180, 180);
    font-size: 16px;
  }
</style>
