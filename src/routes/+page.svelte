<script>
	import QRCode from 'qrcode';

	let selectedTip = null;
	let showSettings = false;
	let showQR = false;
	let venmoHandle = '';
	let billAmount = 50;
	let tipPercentages = { '15%': 0.15, '20%': 0.2, '25%': 0.25 };
	let qrCodeDataURL = '';

	async function generateQRCode(venmoURL) {
		try {
			const dataURL = await QRCode.toDataURL(venmoURL, {
				width: 200,
				margin: 2,
				color: {
					dark: '#000000',
					light: '#FFFFFF'
				}
			});
			return dataURL;
		} catch (error) {
			console.error('Error generating QR code:', error);
			return '';
		}
	}

	function generateVenmoURL(tipAmount) {
		if (!venmoHandle) return '';

		const total = billAmount + tipAmount;
		const handleWithAt = venmoHandle.startsWith('@') ? venmoHandle : `@${venmoHandle}`;

		return `https://venmo.com/?txn=charge&audience=friends&recipients=${encodeURIComponent(handleWithAt)}&amount=${total.toFixed(2)}`;
	}

	async function handleTipSelect(tipPercent) {
		selectedTip = tipPercent;
		const tipAmount = tipPercent ? billAmount * tipPercent : 0;
		const venmoURL = generateVenmoURL(tipAmount);
		qrCodeDataURL = await generateQRCode(venmoURL);
		showQR = true;
		console.log('Selected tip:', tipPercent);
	}

	async function handleCustomTip() {
		// You could add a prompt or input for custom amount
		const customPercent = prompt('Enter custom tip percentage (e.g., 18 for 18%):');
		if (customPercent && !isNaN(customPercent)) {
			const tipPercent = parseFloat(customPercent) / 100;
			await handleTipSelect(tipPercent);
		}
		console.log('Custom tip selected');
	}

	function saveSettings() {
		showSettings = false;
		console.log('Settings saved:', { venmoHandle, tipPercentages });
	}

	function updateTipPercentage(label, value) {
		tipPercentages[label] = value / 100;
	}

	function closeQR() {
		showQR = false;
		selectedTip = null;
		qrCodeDataURL = '';
	}

	$: tipAmount = selectedTip ? billAmount * selectedTip : 0;
	$: venmoURL = generateVenmoURL(tipAmount);
</script>

<div class="flex min-h-screen items-center justify-center bg-gray-50 p-4">
	<div class="w-full max-w-md text-center">
		<!-- Secret Settings Button -->
		<button
			on:click={() => (showSettings = true)}
			class="mb-8 text-xl font-medium text-black transition-colors hover:text-gray-600"
		>
			Add a tip?
		</button>

		<!-- Settings Modal -->
		{#if showSettings}
			<div class="bg-opacity-50 fixed inset-0 z-50 flex items-center justify-center bg-black p-4">
				<div class="w-full max-w-md rounded-lg bg-white p-6">
					<h2 class="mb-4 text-xl font-bold">Settings</h2>

					<!-- Venmo Handle Input -->
					<div class="mb-4">
						<label class="mb-2 block text-left text-sm font-medium text-gray-700">
							Venmo Handle
						</label>
						<input
							type="text"
							bind:value={venmoHandle}
							placeholder="@username or username"
							class="w-full rounded-md border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:outline-none"
						/>
					</div>

					<!-- Bill Amount Input -->
					<div class="mb-4">
						<label class="mb-2 block text-left text-sm font-medium text-gray-700">
							Bill Amount ($)
						</label>
						<input
							type="number"
							bind:value={billAmount}
							placeholder="50.00"
							step="0.01"
							min="0"
							class="w-full rounded-md border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:outline-none"
						/>
					</div>

					<!-- Tip Percentage Inputs -->
					<div class="mb-6">
						<label class="mb-2 block text-left text-sm font-medium text-gray-700">
							Tip Percentages
						</label>
						{#each Object.entries(tipPercentages) as [label, value]}
							<div class="mb-2 flex items-center justify-between">
								<span class="text-sm">{label}</span>
								<div class="flex items-center">
									<input
										type="number"
										value={Math.round(value * 100)}
										on:input={(e) => updateTipPercentage(label, parseFloat(e.target.value) || 0)}
										class="w-16 rounded border border-gray-300 px-2 py-1 text-center text-sm"
										min="0"
										max="100"
									/>
									<span class="ml-1 text-sm">%</span>
								</div>
							</div>
						{/each}
					</div>

					<!-- Buttons -->
					<div class="flex gap-3">
						<button
							on:click={() => (showSettings = false)}
							class="flex-1 rounded-md border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-50"
						>
							Cancel
						</button>
						<button
							on:click={saveSettings}
							class="flex-1 rounded-md bg-blue-500 px-4 py-2 text-white hover:bg-blue-600"
						>
							Save
						</button>
					</div>
				</div>
			</div>
		{/if}

		<!-- QR Code Modal -->
		{#if showQR}
			<div class="bg-opacity-50 fixed inset-0 z-50 flex items-center justify-center bg-black p-4">
				<div class="w-full max-w-sm rounded-lg bg-white p-6 text-center">
					<h2 class="mb-4 text-xl font-bold">Scan to Pay</h2>

					{#if venmoHandle}
						<div class="mb-4">
							{#if qrCodeDataURL}
								<img
									src={qrCodeDataURL}
									alt="Venmo QR Code"
									class="mx-auto mb-4 rounded border-2 border-gray-200"
								/>
							{:else}
								<div
									class="mx-auto mb-4 flex h-[200px] w-[200px] items-center justify-center rounded border-2 border-gray-200"
								>
									<span class="text-gray-500">Generating QR...</span>
								</div>
							{/if}

							<p class="mb-2 text-sm text-gray-600">
								Bill: ${billAmount.toFixed(2)}
							</p>
							<p class="mb-2 text-sm text-gray-600">
								Tip: ${tipAmount.toFixed(2)} ({Math.round(selectedTip * 100)}%)
							</p>
							<p class="text-lg font-semibold text-green-600">
								Total: ${(billAmount + tipAmount).toFixed(2)}
							</p>
							<p class="mt-2 text-xs text-gray-500">
								to {venmoHandle.startsWith('@') ? venmoHandle : `@${venmoHandle}`}
							</p>

							<!-- Direct Link for testing -->
							<div class="mt-4">
								<a
									href={venmoURL}
									target="_blank"
									class="text-xs text-blue-500 underline hover:text-blue-700"
								>
									Open Venmo Link
								</a>
							</div>
						</div>
					{:else}
						<div class="mb-4">
							<p class="mb-2 text-red-500">No Venmo handle set!</p>
							<p class="text-sm text-gray-600">
								Please configure your Venmo handle in settings first.
							</p>
						</div>
					{/if}

					<button
						on:click={closeQR}
						class="w-full rounded-md bg-gray-500 px-4 py-2 text-white hover:bg-gray-600"
					>
						Close
					</button>
				</div>
			</div>
		{/if}

		<!-- Tip Buttons -->
		<div class="mb-4 grid grid-cols-3 gap-4">
			{#each Object.entries(tipPercentages) as [label, value]}
				<button
					class="bg-blue-500 px-4 py-6 text-lg font-semibold text-white transition-colors duration-150 ease-in-out select-none hover:bg-blue-400 active:bg-blue-400"
					on:click={() => handleTipSelect(value)}
				>
					{label}
				</button>
			{/each}
		</div>

		<button
			class="mb-4 w-full bg-blue-500 px-4 py-6 text-lg font-semibold text-white transition-colors duration-150 ease-in-out select-none hover:bg-blue-400 active:bg-blue-400"
			on:click={handleCustomTip}
		>
			Custom
		</button>

		<button
			class="w-full bg-blue-500 px-4 py-6 text-lg font-semibold text-white transition-colors duration-150 ease-in-out select-none hover:bg-blue-400 active:bg-blue-400"
			on:click={() => handleTipSelect(0)}
		>
			No tip
		</button>
	</div>
</div>

