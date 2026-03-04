extends GutTest

func before_each() -> void:
	GameState.reset()
	ContractManager.reset()

# --- Initial state ---
func test_starts_with_available_contracts() -> void:
	assert_gte(ContractManager.available_contracts.size(), 2)
	assert_lte(ContractManager.available_contracts.size(), 3)

func test_starts_with_no_active_contracts() -> void:
	assert_eq(ContractManager.active_contracts.size(), 0)

func test_max_active_contracts_is_2() -> void:
	assert_eq(ContractManager.MAX_ACTIVE, 2)

# --- Contract structure ---
func test_contract_has_required_fields() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_has(contract, "contract_id")
	assert_has(contract, "client_name")
	assert_has(contract, "required_style")
	assert_has(contract, "minimum_quality")
	assert_has(contract, "reward")
	assert_has(contract, "bonus_reward")
	assert_has(contract, "deadline_turns")
	assert_has(contract, "remaining_turns")
	assert_has(contract, "reputation_penalty")

func test_contract_quality_in_valid_range() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	var quality: float = contract.get("minimum_quality", 0.0)
	assert_gte(quality, 30.0)
	assert_lte(quality, 80.0)

func test_contract_reward_positive() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_gt(contract.get("reward", 0), 0)

func test_contract_deadline_positive() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_gt(contract.get("deadline_turns", 0), 0)

# --- Accept ---
func test_accept_moves_to_active() -> void:
	var cid: String = ContractManager.available_contracts[0]["contract_id"]
	var result: bool = ContractManager.accept(cid)
	assert_true(result)
	assert_eq(ContractManager.active_contracts.size(), 1)

func test_accept_removes_from_available() -> void:
	var initial_count: int = ContractManager.available_contracts.size()
	var cid: String = ContractManager.available_contracts[0]["contract_id"]
	ContractManager.accept(cid)
	assert_eq(ContractManager.available_contracts.size(), initial_count - 1)

func test_cannot_accept_more_than_max() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.generate_contracts()
	var result: bool = ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	assert_false(result)
	assert_eq(ContractManager.active_contracts.size(), 2)

func test_accept_nonexistent_fails() -> void:
	var result: bool = ContractManager.accept("fake_id")
	assert_false(result)

# --- Generation ---
func test_generate_creates_2_to_3() -> void:
	ContractManager.generate_contracts()
	assert_gte(ContractManager.available_contracts.size(), 2)
	assert_lte(ContractManager.available_contracts.size(), 3)

func test_contracts_use_valid_styles() -> void:
	for contract in ContractManager.available_contracts:
		assert_true(contract["required_style"] in ContractManager.STYLE_IDS,
			"Style %s should be valid" % contract["required_style"])

# --- Refresh counter ---
func test_refresh_interval() -> void:
	assert_eq(ContractManager.REFRESH_INTERVAL, 3)

func test_refresh_counter_starts_at_interval() -> void:
	assert_eq(ContractManager.refresh_counter, ContractManager.REFRESH_INTERVAL)

# --- Persistence ---
func test_save_and_load() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.refresh_counter = 1
	var data: Dictionary = ContractManager.save_state()
	ContractManager.reset()
	assert_eq(ContractManager.active_contracts.size(), 0)
	ContractManager.load_state(data)
	assert_eq(ContractManager.active_contracts.size(), 1)
	assert_eq(ContractManager.refresh_counter, 1)

# --- Signals ---
func test_contract_accepted_signal() -> void:
	watch_signals(ContractManager)
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	assert_signal_emitted(ContractManager, "contract_accepted")
