import 'package:economize/model/moedas/country_currency.dart';
import 'package:economize/repository/countries_repository.dart';
import 'package:economize/screen/home_screen.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animations/fade_animation.dart';
import '../../animations/scale_animation.dart';
import '../../animations/slide_animation.dart';

class CountrySelectionScreen extends StatefulWidget {
  /// Se verdadeiro, permite voltar para tela anterior (para configurações)
  /// Se falso, é obrigatório escolher (primeira execução)
  final bool canGoBack;

  const CountrySelectionScreen({
    super.key,
    this.canGoBack = false,
  });

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen>
    with SingleTickerProviderStateMixin {
  CountryCurrency? _detectedCountry;
  CountryCurrency? _selectedCountry;
  late AnimationController _animationController;
  final CurrencyService _currencyService = CurrencyService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _detectCountry();
    _animationController.forward();
  }

  void _detectCountry() {
    _detectedCountry = CurrencyService.detectCountryFromDevice();
    _selectedCountry = _detectedCountry ?? CountriesRepository.getDefault();
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fundo claro único
      appBar: widget.canGoBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: const Text(
                'Escolher Moeda',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header com ícone animado
              SlideAnimation.fromTop(
                delay: const Duration(milliseconds: 200),
                child: _buildHeader(),
              ),

              const SizedBox(height: 32),

              // Detecção automática (se houver)
              if (_detectedCountry != null) ...[
                SlideAnimation.fromLeft(
                  delay: const Duration(milliseconds: 400),
                  child: _buildDetectedSection(),
                ),
                const SizedBox(height: 24),
              ],

              // Lista de países
              Expanded(
                child: SlideAnimation.fromBottom(
                  delay: const Duration(milliseconds: 600),
                  child: _buildCountriesList(),
                ),
              ),

              // Botão de confirmação
              SlideAnimation.fromBottom(
                delay: const Duration(milliseconds: 800),
                child: _buildConfirmButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleAnimation.bounceIn(
          delay: const Duration(milliseconds: 300),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha((0.3 * 255).toInt()),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.language,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeAnimation.fadeIn(
          delay: const Duration(milliseconds: 500),
          child: const Text(
            'Escolha seu País',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeAnimation.fadeIn(
          delay: const Duration(milliseconds: 700),
          child: const Text(
            'Isso definirá a moeda usada em todo o app',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedSection() {
    if (_detectedCountry == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withAlpha((0.1 * 255).toInt()),
            const Color(0xFF8B5CF6).withAlpha((0.1 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.3 * 255).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Detectamos automaticamente:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCountryCard(
            _detectedCountry!,
            isSelected:
                _selectedCountry?.countryCode == _detectedCountry!.countryCode,
            isDetected: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ou escolha manualmente:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: CountriesRepository.supportedCountries.length,
            itemBuilder: (context, index) {
              final country = CountriesRepository.supportedCountries[index];
              return SlideAnimation.fromRight(
                delay: Duration(milliseconds: 100 * index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCountryCard(
                    country,
                    isSelected:
                        _selectedCountry?.countryCode == country.countryCode,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCard(
    CountryCurrency country, {
    required bool isSelected,
    bool isDetected = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCountry = country;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha((0.3 * 255).toInt()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withAlpha((0.5 * 255).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Flag Emoji
            Text(
              country.flagEmoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),

            // Country Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.countryName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${country.currencyName} (${country.currencySymbol})',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withAlpha((0.9 * 255).toInt())
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF6366F1),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final isEnabled = _selectedCountry != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? _confirmSelection : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnabled ? 4 : 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedCountry != null) ...[
              Text(_selectedCountry!.flagEmoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
            ],
            Text(
              isEnabled
                  ? 'Usar ${_selectedCountry!.currencyName}'
                  : 'Selecione um país',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSelection() async {
    if (_selectedCountry == null) return;

    try {
      // Salva a seleção
      await _currencyService.setSelectedCountry(_selectedCountry!);
      await CurrencyService.markAsConfigured();

      if (!mounted) return;

      // ❌ REMOVER ESTA LINHA PROBLEMÁTICA:
      // HomeScreen.refreshHomeData();

      // Navega para a home ou volta
      if (widget.canGoBack) {
        Navigator.pop(context, true); // ✅ Retorna resultado para forçar refresh
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }

      // Feedback visual com a nova moeda
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(_selectedCountry!.flagEmoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Moeda alterada para ${_selectedCountry!.currencyName}! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar configuração: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
