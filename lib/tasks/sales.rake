namespace :sales do
  desc "Vincula vendas sem vendedor ao membro cujo username corresponde ao responsável"
  task link_sellers: :environment do
    puts "#{Sale.link_unlinked_sellers} venda(s) vinculada(s)."
  end
end
