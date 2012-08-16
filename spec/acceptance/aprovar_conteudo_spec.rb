# encoding: utf-8

require 'spec_helper'

feature 'aprovar conteúdo' do
  before(:each) do
    Papel.criar_todos
  end

  scenario 'envia conteúdo para granularização ao aprovar' do
    usuario = autenticar_usuario(Papel.gestor)
    artigo = create(:artigo_de_evento_pendente,
      arquivo_para_conteudo(:odt).merge(campus: usuario.campus))
    visit conteudo_path(artigo)
    click_button 'Aprovar'
    artigo.reload.should be_granularizando
    page.driver.post(granularizou_conteudos_path,
                     doc_key: artigo.arquivo.key,
                     grains_keys: {
                       images: 2.times.map {|n| rand.to_s.split('.').last },
                       files: [rand.to_s.split('.').last]
                      },
                      thumbnail_key: 'a dummy key')
    artigo.reload.should be_publicado
    artigo.should have(2).graos_imagem
    artigo.should have(1).graos_arquivo
    artigo.arquivo.thumbnail_key.should == 'a dummy key'
  end

  # TODO: cogitar escrita como teste de unidade de view
  scenario 'gestor de instituição não pode aprovar conteudo de outra instituição' do
    Papel.criar_todos
    campus1 = create(:campus)
    campus2 = create(:campus, instituicao: campus1.instituicao)
    campus_outro = create(:campus)

    gestor1 = create(:usuario_gestor, campus: campus1)
    gestor2 = create(:usuario_gestor, campus: campus2)
    gestor_outro = create(:usuario_gestor, campus: campus_outro)

    conteudo = create(:relatorio_pendente, campus: campus1)

    [gestor1, gestor2].each do |gestor|
      autenticar(gestor)
      visit conteudo_path(conteudo)
      page.should have_button 'Aprovar'
    end
    
    autenticar(gestor_outro)
    visit conteudo_path(conteudo)
    page.should_not have_button 'Aprovar'
  end
end
