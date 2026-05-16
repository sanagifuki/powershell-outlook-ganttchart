# 汎用関数
# ========================
function Format-Memo($m) {
    if ($null -eq $m -or [string]::IsNullOrWhiteSpace($m)) { return "" }
    # GAS版 convertHtmlToPlainText の移植: HTMLタグ由来の改行を正規化
    $m = $m -replace '<br\s*/?>', "`n"
    $m = $m -replace '</p>|</div>', "`n"
    $m = $m -replace '<li>', "・"
    $m = $m -replace '</li>', "`n"
    $m = $m -replace '<[^>]+>', ""
    # 特殊な制御文字や連続スペースを整形
    $m = $m -replace "\t| +", " "
    # 改行コードの統一 (`n) と過剰な連続改行の抑制
    $m = $m -replace "`r`n|`r", "`n"
    $m = $m -replace "`n{3,}", "`n`n"
    # 箇条書き記号直後の不自然な改行（* \n 等）を抑制
    $m = $m -replace '([\*・])\s*\n', '$1 '
    # 箇条書き記号の統一 (* -> ・)
    $m = $m -replace '(?m)^\*\s*', "・"
    return $m.Trim()
}

