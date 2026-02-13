namespace MtcSales.API.Services;

public class PriceCodeService
{
    // Mapping: 1 2 3 4 5 6 7 8 9 0
    // Chars:   M A C H I N E R Y S
    private static readonly char[] _codeMap = { 'S', 'M', 'A', 'C', 'H', 'I', 'N', 'E', 'R', 'Y' };
    // Index 0 -> 'S' (value 0)
    // Index 1 -> 'M' (value 1)
    // ...
    // Index 9 -> 'Y' (value 9)

    public string Encode(decimal price)
    {
        // Convert to integer (remove decimals for simplicity in MVP, or handle cents)
        // Usually cost codes are for whole numbers. Let's assume whole numbers.
        int value = (int)price;
        string valueStr = value.ToString();
        
        char[] result = new char[valueStr.Length];
        for (int i = 0; i < valueStr.Length; i++)
        {
            int digit = int.Parse(valueStr[i].ToString());
            result[i] = _codeMap[digit];
        }

        return new string(result);
    }

    public decimal? Decode(string code)
    {
        if (string.IsNullOrWhiteSpace(code)) return null;

        string codeUpper = code.ToUpper();
        string numberStr = "";

        foreach (char c in codeUpper)
        {
            int index = Array.IndexOf(_codeMap, c);
            if (index == -1) return null; // Invalid character
            numberStr += index.ToString();
        }

        if (decimal.TryParse(numberStr, out decimal result))
        {
            return result;
        }
        return null;
    }

    public bool IsValidCode(string code)
    {
        if (string.IsNullOrWhiteSpace(code)) return false;
        string codeUpper = code.ToUpper();
        foreach (char c in codeUpper)
        {
            if (Array.IndexOf(_codeMap, c) == -1) return false;
        }
        return true;
    }
}
