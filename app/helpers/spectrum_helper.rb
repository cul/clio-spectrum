module SpectrumHelper

  def get_column_classes(column)
    "result_column span#{column['width']}"
  end

  def truncated_doc_list(result, count)
    if count
      result[:docs][0,count]
    else
      result[:docs]

    end
  end
end
