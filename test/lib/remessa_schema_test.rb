# test/lib/remessa_schema_test.rb
require "test_helper"
# require "remessa_schema"
require "bigdecimal"

class RemessaSchemaTest < ActiveSupport::TestCase
  def setup
    @schema_file = Rails.root.join("test", "fixtures", "remessa_schema.yml")
    @schema = RemessaSchema.load_schema(@schema_file)
  end

  test "load_schema loads the YAML file" do
    assert_kind_of Hash, @schema
    assert @schema.key?("header")
    assert @schema.key?("registro_movimento")
  end

  test "load_schema raises an error if the file is not found" do
    assert_raises(RuntimeError) { RemessaSchema.load_schema("nonexistent_schema.yml") }
  end

  test "extract_data extracts header data from a line according to the schema" do
    line = "01REMESSA01COBRANCA       46820244241801300557ASSISTENCIA ANIMAL COM DE PROD" + " " * 311 + "000001"
    schema = @schema["header"]
    extracted_data = RemessaSchema.extract_data(line, schema)

    assert_equal "0", extracted_data[:"Código do Registro"]
    assert_equal "1", extracted_data[:"Código da Remessa"]
    assert_equal "REMESSA", extracted_data[:"Literal de Transmissão"]
    assert_equal "01", extracted_data[:"Código do Tipo Serviço"]
    assert_equal "COBRANCA       ", extracted_data[:"Literal de Serviço"]
    assert_equal "46820244241801300557", extracted_data[:"Código de Transmissão"]
    assert_equal "ASSISTENCIA ANIMAL COM DE PROD", extracted_data[:"Nome do Beneficiário"]
  end

  test "extract_data extracts registro_movimento data with decimal places" do
    line = "1020274838500010346820244241801300557000000000000000000540726A0183763000000 40200000000000000000    091224502000295479A061224\t000000004284\t30330468201N051124000400000000000430000000000000000000000000000000000000000000000255914786000144FLEIDITON MILIOLI CAMPOS BISPO          AVENIDA SAO RAFAEL, 303 - EDIF QD BV BL SAO MARCOS  41253190SALVADOR       BA                               I45      00 000002"
    schema = @schema["registro_movimento"]
    extracted_data = RemessaSchema.extract_data(line, schema)

    assert_equal BigDecimal("0.00"), extracted_data[:"Percentual de Multa"]
    assert_equal BigDecimal("0.00"), extracted_data[:"Valor do boleto em outra unidade"]
    assert_equal BigDecimal("42.84"), extracted_data[:"Valor nominal do boleto"]
    assert_equal BigDecimal("0.00"), extracted_data[:"Valor de Mora dia"]
    assert_equal BigDecimal("0.00"), extracted_data[:"Valor do desconto a ser concedido"]
    assert_equal BigDecimal("0.00000"), extracted_data[:"Percentual do IOF a ser recolhido"]
    assert_equal BigDecimal("0.00"), extracted_data[:"Valor do abatimento ou Valor do segundo desconto"]
  end
end
