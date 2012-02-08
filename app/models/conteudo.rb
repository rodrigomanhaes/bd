# encoding: utf-8

class Conteudo < ActiveRecord::Base
  has_many :autores
  accepts_nested_attributes_for :autores, :reject_if => :all_blank
  validate :nao_pode_ter_arquivo_e_link_simultaneamente,
           :arquivo_ou_link_devem_existir
  validates :titulo, :grande_area_de_conhecimento, :area_de_conhecimento,
            :campus, :autores, :presence => true

  private

  def nao_pode_ter_arquivo_e_link_simultaneamente
    if arquivo.present? && link.present?
      errors.add(:arquivo, 'não pode existir simultaneamente a link')
      errors.add(:link, 'não pode existir simultaneamente a arquivo')
    end
  end

  def arquivo_ou_link_devem_existir
    if arquivo.blank? && link.blank?
      errors.add(:arquivo, 'deve ser fornecido (ou informe um link)')
      errors.add(:link, 'deve ser informado (ou forneça um arquivo)')
    end
  end
end