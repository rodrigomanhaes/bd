# encoding: utf-8

require 'spec_helper'
Dir.glob(Rails.root + '/app/models/*.rb').each { |file| require file }

feature 'Buscas' do
  before(:each) do
    Tire.criar_indices
    Papel.criar_todos
  end

  def refresh_elasticsearch
    Arquivo.tire.index.refresh
    Conteudo.tire.index.refresh
  end

  context 'busca avançada (busca no acervo)', busca: true do
    scenario 'deve buscar por título' do
      livro = create(:livro_publicado)
      refresh_elasticsearch

      visit buscas_path
      fill_in 'parametros[titulo]', with: livro.titulo
      click_button 'Buscar'

      page.should have_content livro.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario 'busca pelo nome do autor' do
      livro = create(:livro_publicado)
      refresh_elasticsearch

      visit buscas_path
      fill_in 'parametros[nome]', with: livro.autores.first.nome
      click_button 'Buscar'
      page.should have_content livro.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario 'busca por tipo de conteúdo' do
      livro = create(:livro_publicado, titulo: "teste livro")
      artigo = create(:artigo_de_periodico_publicado, titulo: "teste artigo")
      refresh_elasticsearch

      visit buscas_path
      fill_in 'parametros[titulo]', with: "teste"
      check('Livro')
      click_button 'Buscar'
      page.should have_content livro.titulo
      page.should_not have_content artigo.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario 'busca por tipo de conteúdo PRONATEC' do
      pronatec = create(:pronatec, titulo: "teste pronatec")
      aprovar(pronatec)
      objeto_de_aprendizagem = create(:objeto_de_aprendizagem_publicado, titulo: "teste aprendizagem")
      refresh_elasticsearch

      visit buscas_path
      check('PRONATEC')
      click_button 'Buscar'
      page.should have_content pronatec.titulo
      page.should_not have_content objeto_de_aprendizagem.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario 'busca por mais de tipo de conteúdo' do
      livro = create(:livro_publicado, titulo: "teste livro")
      artigo = create(:artigo_de_periodico_publicado, titulo: "teste artigo")
      refresh_elasticsearch

      visit buscas_path
      fill_in 'parametros[titulo]', with: "teste"
      check('Livro')
      check('Artigo de Periódico')
      click_button 'Buscar'
      page.should have_content livro.titulo
      page.should have_content artigo.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

   scenario 'busca pelo nome da área' do
     livro = create(:livro_publicado, titulo: "teste livro")
     refresh_elasticsearch

     visit buscas_path
     select livro.nome_area, from: 'parametros[nome_area]'
     click_button 'Buscar'
     page.should have_content livro.titulo
     page.should_not have_content("Não foi encontrado resultado para sua busca.")
   end

   scenario 'busca pelo nome da sub-área', js: true do
     livro = create(:livro_publicado, titulo: "teste livro")
     refresh_elasticsearch

     visit buscas_path
     select livro.nome_area, from: 'parametros[nome_area]'
     wait_until { page.has_selector?("select:has(option:contains('Todas'))[name='parametros[nome_instituicao]']") }
     select livro.nome_sub_area, from: 'parametros[nome_sub_area]'
     click_button 'Buscar'
     page.should have_content livro.titulo
     page.should_not have_content("Não foi encontrado resultado para sua busca.")
   end

    scenario 'busca pelo nome da instituição' do
      livro = create(:livro_publicado, titulo: "teste livro")
      refresh_elasticsearch

      visit buscas_path
      select livro.nome_instituicao, from: 'parametros[nome_instituicao]'
      click_button 'Buscar'
      page.should have_content livro.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario 'busca por texto-integral' do
      livro = create(:livro_publicado, resumo: 'texto integral')
      refresh_elasticsearch

      visit buscas_path
      fill_in 'busca', with: livro.resumo
      click_button 'Buscar'

      page.should have_content livro.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

    scenario "em uma busca vazia não retornar resultados" do
      visit buscas_path
      click_button 'Buscar'
      page.should have_content "Busca não realizada. Favor preencher algum critério de busca"
    end
  end

  scenario 'busca por texto-integral deve buscar no arquivo' do
      Arquivo.destroy_all # TODO: isso não devia ser necessário
      livro = create(:livro_publicado, titulo: "teste livro", link: '',
                      arquivo: Arquivo.new(
                                uploaded_file: ActionDispatch::Http::UploadedFile.new(
                                  {filename: 'arquivo.rtf', type: 'text/rtf',
                                   tempfile: File.new(Rails.root + 'spec/resources/arquivo.rtf')}
                                )
                              )
                    )
      refresh_elasticsearch
      visit buscas_path
      fill_in 'busca', with: "winter"
      click_button 'Buscar'
      page.should have_content livro.titulo
      page.should_not have_content("Não foi encontrado resultado para sua busca.")
    end

  scenario 'salvar busca' do
    usuario = autenticar_usuario(Papel.membro)
    livro = create(:livro_publicado, titulo: 'My book')
    livro2 = create(:livro_publicado, titulo: 'Outro book')
    Conteudo.index.refresh

    visit root_path
    fill_in 'text_busca_inicio', with: 'book'
    click_button 'Buscar'
    click_link 'Salvar Busca'
    fill_in 'Título', with: 'Buscas book'
    fill_in 'Descriçao', with: 'Primeira busca'
    click_button 'Salvar'

    page.should have_content 'Busca salva com sucesso'
    visit root_path
    page.should have_link 'Buscas book'
  end

  scenario 'clicar na busca salva executa a busca novamente' do
    usuario = autenticar_usuario(Papel.contribuidor)
    artigo = create(:artigo_de_evento_publicado, titulo: 'artigo')
    Conteudo.index.refresh

    create(:busca, titulo: "busca por artigo", busca: 'artigo', usuario: usuario)

    visit root_path
    #link do portlet
    click_link 'busca por artigo'
    within '#resultado' do
      page.should have_link 'artigo'
    end

    #link da view minhas buscas
    click_link 'Gerenciar buscas'
    click_link 'busca por artigo'
    within '#resultado' do
      page.should have_link 'artigo'
    end
  end

  scenario 'ver minhas buscas' do
    usuario = autenticar_usuario(Papel.membro)
    page.should_not have_link 'Gerenciar buscas'

    livro = create(:livro_publicado, titulo: 'livro')
    Conteudo.index.refresh

    visit root_path
    fill_in 'text_busca_inicio', with: 'livro'
    click_button 'Buscar'
    click_link 'Salvar Busca'
    fill_in 'Título', with: 'Buscar livro'
    click_button 'Salvar'

    page.should have_link 'Buscar livro'
    page.should have_link 'Gerenciar buscas'

    click_link 'Gerenciar buscas'
    page.should have_content 'Minhas Buscas'
    page.should have_link 'Buscar livro'
    page.should have_link 'Editar'
    page.should have_link 'Deletar'

  end

  scenario 'cadastrar busca salva no servico de mala direta', busca: true do
    usuario = autenticar_usuario(Papel.contribuidor)
    create(:livro_publicado, titulo: 'livro')
    Conteudo.index.refresh

    visit root_path
    fill_in 'text_busca_inicio', with: 'livro'
    click_button 'Buscar'
    click_link 'Salvar Busca'

    fill_in 'Título', with: 'Buscar livro'
    click_button 'Salvar'

    page.should have_link 'Buscar livro'
    page.should have_link 'Gerenciar buscas'
    page.should have_link 'Mala direta'

    Busca.count.should == 1
    click_link 'Gerenciar buscas'

    busca = Busca.first
    busca.mala_direta.should be_false

    busca.mala_direta = true
    busca.mala_direta.should be_true
  end

  scenario 'nenhuma busca salva' do
    usuario = autenticar_usuario(Papel.membro)
    visit root_path
    within '#minhas_buscas' do
      page.should have_content 'Não há buscas salvas.'
    end
    visit minhas_buscas_usuario_path(usuario)
    within '.content' do
      page.should have_content 'Não há buscas salvas.'
    end
  end

  scenario 'usuario não autenticado não pode salvar buscas' do
    visit buscas_path
    page.should_not have_content "Salvar Busca"
  end
end
