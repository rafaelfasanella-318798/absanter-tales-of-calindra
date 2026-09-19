extends GutTest


func test_data_validator_all_valid() -> void:
	var results: Dictionary = DataValidator.validate_all()
	assert_true(results["success"], "Data validator found errors: %s" % str(results["errors"]))
	assert_gt(results["validated_count"], 10)
	assert_eq(results["errors"].size(), 0)


func test_export_balance_csv() -> void:
	var temp_path: String = "user://test_balance_summary.csv"
	var success: bool = BalanceExporter.export_csv(temp_path)
	assert_true(success)
	assert_true(FileAccess.file_exists(temp_path))

	var file: FileAccess = FileAccess.open(temp_path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()

	assert_true("ragg" in content)
	assert_true("calindra" in content)
	assert_true("slime" in content)
	assert_true("kakariko_golem" in content)
