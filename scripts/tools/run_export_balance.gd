extends SceneTree
## Headless CLI runner for BalanceExporter.


func _init() -> void:
	print("==> Exportando resumo de balanceamento...")
	var success: bool = BalanceExporter.export_csv("res://data/balance_summary.csv")
	if success:
		print("==> SUCESSO: data/balance_summary.csv gerado com êxito!")
		quit(0)
	else:
		printerr("==> FALHA: Erro ao gerar data/balance_summary.csv")
		quit(1)
